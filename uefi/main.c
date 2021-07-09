#include "bob.h"
#include <efi.h>
#include <efilib.h>
#include <stdint.h>

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

void buf64(unsigned long n)
{
	unsigned i = 0;
	unsigned sft = 60;
	unsigned long mask = 0xf;
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
	}
}

EFI_STATUS efi_main(EFI_HANDLE image_handle, EFI_SYSTEM_TABLE *system_table)
{
	ST = system_table;

	dumpVga(ST);

	waitForKey(ST);

	return 0;
}

