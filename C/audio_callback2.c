#import <stdio.h>
#import <string.h>
#import <stdbool.h>
#import <stdlib.h>

struct Sound {
    unsigned char *Data;
    int length;
};

void audio_callback(void *userdata, u_int8_t *stream, int len) {
    //printf("%d\n", len);
    struct Sound *s_data = (struct Sound *)userdata;
    for (int i=0; i<len; i++) {
        if (i<s_data->length) {
            stream[i] = s_data->Data[i];
        } else {
            //stream[i] = s_data->Data[i % s_data->length];
            stream[i] = 0;
        }
    }
}
