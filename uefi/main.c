#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include "bob.h"

extern void kernel_main();

EFI_SYSTEM_TABLE *ST = 0;
struct Bob bob;
CHAR16 num_buf[17];
EFI_GUID vga_guid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;

void waitForKey(EFI_SYSTEM_TABLE *ST)
{
	EFI_STATUS status;
	EFI_INPUT_KEY key;
	/* Clear keyboard buffer */
	status = ST->ConIn->Reset(ST->ConIn, FALSE);
	if (EFI_ERROR(status))
		return;

	/* Wait for key press */
	while ((status = ST->ConIn->ReadKeyStroke(ST->ConIn, &key)) == EFI_NOT_READY)
		; // do nothing
}

unsigned char hexChar(unsigned n)
{
	if (n < 10)
		return n + '0';
	return n - 10 + 'A';
}

void buf32(unsigned n)
{
	unsigned i = 0;
	unsigned sft = 28;
	unsigned mask = 0xf0000000;
	for (i = 0; i < 8; ++i)
	{
		num_buf[i] = hexChar((n & mask) >> sft);
		sft -= 4;
		mask >>= 4;
	}
	num_buf[i] = 0;
}

void buf64(UINT64 n)
{
	unsigned i = 0;
	unsigned sft = 60;
	UINT64 mask = 0xf;
	mask <<= sft;
	for (i = 0; i < 16; ++i)
	{
		num_buf[i] = hexChar((n & mask) >> sft);
		sft -= 4;
		mask >>= 4;
	}
	num_buf[i] = 0;
}

void dumpVga(EFI_SYSTEM_TABLE *ST)
{
	EFI_STATUS status;
	UINTN num_handles = 0;
	EFI_HANDLE *buffer = 0;
	unsigned i = 0;

	status = ST->BootServices->LocateHandleBuffer(ByProtocol, &vga_guid, 0, &num_handles, &buffer);
	if (EFI_ERROR(status))
	{
		ST->ConOut->OutputString(ST->ConOut, L"Locate Handle Failed\r\n");
		return;
	}

	for (i = 0; i < num_handles; ++i)
	{
		unsigned j = 0;
		EFI_GRAPHICS_OUTPUT_PROTOCOL *vga_iface = 0;
		UINTN info_size = 0;
		UINT32 best_mode = 0;
		UINT32 best_width = 0;
		UINT32 best_height = 0;

		status = ST->BootServices->HandleProtocol(buffer[i], &vga_guid, (void**)&vga_iface);
		if (EFI_ERROR(status))
		{
			ST->ConOut->OutputString(ST->ConOut, L"Handle Protocol Failed\r\n");
			return;
		}

		for (j = 0; j < vga_iface->Mode->MaxMode; ++j)
		{
			EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *vga_mode = 0;
			status = vga_iface->QueryMode(vga_iface, j, &info_size, &vga_mode);
			if (EFI_ERROR(status))
			{
				ST->ConOut->OutputString(ST->ConOut, L"Query Mode Failed\r\n");
				continue;
			}

			// don't take anything too tall
			if (vga_mode->VerticalResolution > 1024)
				continue;

			// if we have a short window
			if (best_height < 1024)
			{
				// and this is taller
				if (vga_mode->VerticalResolution > best_height)
				{
					// take it
					best_mode = j;
					best_height = vga_mode->VerticalResolution;
					best_width  = vga_mode->HorizontalResolution;
					continue;
				}
			}

			// don't take anything shorter
			if (vga_mode->VerticalResolution < best_height)
				continue;

			// take something wider
			if (vga_mode->HorizontalResolution > best_width)
			{
				best_mode = j;
				best_height = vga_mode->VerticalResolution;
				best_width  = vga_mode->HorizontalResolution;
				continue;
			}
		}
		ST->ConOut->OutputString(ST->ConOut, L"Best Mode ");
		buf32(best_width);
		ST->ConOut->OutputString(ST->ConOut, num_buf);
		ST->ConOut->OutputString(ST->ConOut, L" x ");
		buf32(best_height);
		ST->ConOut->OutputString(ST->ConOut, num_buf);
		ST->ConOut->OutputString(ST->ConOut, L"\r\n");

		waitForKey(ST);
		vga_iface->SetMode(vga_iface, best_mode);

		if (i == 0)
		{
			bob.vga_width = best_width;
			bob.vga_height = best_height;
			bob.vga_bpp = 32;
			bob.vga_lfbp = vga_iface->Mode->FrameBufferBase;
		}
	} // foreach video handle
	ST->BootServices->FreePool(buffer);
}

void dumpMem(EFI_SYSTEM_TABLE *ST)
{
	UINTN memory_map_size = 0;
	EFI_MEMORY_DESCRIPTOR memory_map;
	EFI_MEMORY_DESCRIPTOR *memory_desc = 0;
	UINTN map_key = 0;
	UINTN descriptor_size = 0;
	UINT32 descriptor_version = 0;
	EFI_STATUS status;
	char *byte_ptr = 0;
	unsigned i = 0;
	unsigned num_desc = 0;
	unsigned valid = 0;
	UINT64 total_mem = 0;
	unsigned num_printed = 0;
	UINT64 *mem_block = 0;

	status = ST->BootServices->GetMemoryMap(
	    &memory_map_size,
	    &memory_map,
	    &map_key,
	    &descriptor_size,
	    &descriptor_version
	);
	if (status == EFI_SUCCESS)
	{
		// weird
		ST->ConOut->OutputString(ST->ConOut, L"First call to GetMemoryMap succeeded?");
		return;
	}
	if (status != EFI_BUFFER_TOO_SMALL)
	{
		ST->ConOut->OutputString(ST->ConOut, L"First call to GetMemoryMap unahndled error");
		return;
	}

	// make the second call with a big buffer
	// (allocating memory can change the map)
	memory_map_size *= 2;

	// allocate the buffer
	status = ST->BootServices->AllocatePool(EfiLoaderData, memory_map_size, (void**)&byte_ptr);
	if (EFI_ERROR(status))
	{
		ST->ConOut->OutputString(ST->ConOut, L"GetMemoryMap couldn't allocate buffer");
		return;
	}
	status = ST->BootServices->GetMemoryMap(
	    &memory_map_size,
	    (EFI_MEMORY_DESCRIPTOR*)byte_ptr,
	    &map_key,
	    &descriptor_size,
	    &descriptor_version
	);
	if (EFI_ERROR(status))
	{
		ST->ConOut->OutputString(ST->ConOut, L"GetMemoryMap second call failed");
		return;
	}

	// pointer arithmetic
	num_desc = memory_map_size / descriptor_size;
	for (i = 0; i < num_desc; ++i)
	{
		memory_desc = (EFI_MEMORY_DESCRIPTOR*)byte_ptr;
		valid = 0;
		switch (memory_desc->Type)
		{
		case EfiReservedMemoryType: // not usable
		case EfiLoaderCode: // we could try and find dead code and reuse memory...
		case EfiLoaderData: // this is data we have pointers to, we could try to reuse it...
		case EfiRuntimeServicesCode: // EFI is going to use this
		case EfiRuntimeServicesData: // EFI is going to use this
		case EfiACPIReclaimMemory:   // reclaimable after ACPI enabled (we'd need to mark it somehow)
		case EfiACPIMemoryNVS: // not usable
		case EfiMemoryMappedIO: // not usable
		case EfiMemoryMappedIOPortSpace: // not usable
		case EfiPalCode: // not usable
			break;

		case EfiBootServicesCode: // usable after exit
		case EfiBootServicesData: // usable after exit
			//break;

		case EfiConventionalMemory: // usable
			valid = 1;
			break;

		case EfiUnusableMemory: // has errors (report to user?)
			break;
		}
		// advance to next descriptor
		byte_ptr += descriptor_size;

		if (valid == 0)
			continue;

		// boot services memory cannot be written until after exit
		//mem_block = (UINT64*)memory_desc->PhysicalStart;
		//mem_block[0] = bob.free_list;
		//mem_block[1] = memory_desc->NumberOfPages * 4096;
		//bob.free_list = (UINT64)mem_block;

		total_mem += memory_desc->NumberOfPages * 4096;
	}
	ST->ConOut->OutputString(ST->ConOut, L"Total mem ");
	buf64(total_mem);
	ST->ConOut->OutputString(ST->ConOut, num_buf);
}

EFI_STATUS efi_main(EFI_HANDLE image_handle, EFI_SYSTEM_TABLE *system_table)
{
	ST = system_table;

	dumpVga(ST);
	dumpMem(ST);

	waitForKey(ST);

	kernel_main();

	return 0;
}

