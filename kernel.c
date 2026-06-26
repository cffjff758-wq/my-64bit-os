#define VIDEO_ADDRESS 0xB8000
#define WHITE_ON_BLACK 0x0F

void kernel_main() {
    char *video_memory = (char*) VIDEO_ADDRESS;

    for (int i = 0; i < 80 * 25 * 2; i += 2) {
        video_memory[i] = ' ';
        video_memory[i+1] = WHITE_ON_BLACK;
    }

    const char *str = "Welcome to your 64-Bit Operating System!";
    int i = 0;

    while (str[i] != '\0') {
        video_memory[i * 2] = str[i];
        video_memory[i * 2 + 1] = WHITE_ON_BLACK;
        i++;
    }

    while (1) {
        __asm__ __volatile__("hlt");
    }
}
