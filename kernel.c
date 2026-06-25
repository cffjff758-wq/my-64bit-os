void kernel_main() {
    // Address of VGA text mode video memory in 64-bit
    char *video_memory = (char *) 0xB8000;
    
    // The message to print on the screen
    const char *message = "Hello from 64-bit iPad OS!";
    
    int i = 0;
    // Loop through each character of the string
    while (message[i] != '\0') {
        // Set the character byte
        video_memory[i * 2] = message[i];
        // Set the attribute byte (0x02 = Green text on Black background)
        video_memory[i * 2 + 1] = 0x02;
        i++;
    }

    // Infinite loop to halt the CPU execution safely
    while(1) {
        __asm__ __volatile__("hlt");
    }
}