#include <efi.h>
#include <efilib.h>

EFI_SYSTEM_TABLE *ST = 0;

EFI_STATUS efi_main(EFI_HANDLE image_handle, EFI_SYSTEM_TABLE *system_table)
{
	EFI_STATUS status;
	EFI_INPUT_KEY key;

	ST = system_table;

	status = ST->ConOut->OutputString(ST->ConOut, L"Hello World\r\n");
	if (EFI_ERROR(status))
		return status;

	/* Clear keyboard buffer */
	status = ST->ConIn->Reset(ST->ConIn, FALSE);
	if (EFI_ERROR(status))
		return status;

	/* Wait for key press */
	while ((status = ST->ConIn->ReadKeyStroke(ST->ConIn, &key)) == EFI_NOT_READY)
		; // do nothing

	return status;
}

