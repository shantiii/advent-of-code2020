#include <stdio.h>

int main() {
	int buf[1024] = {0};
	size_t buf_len = 0;

	while (scanf("%d\n", buf + buf_len) == 1) {
		++buf_len;
	}

	for(size_t i = 0; i < buf_len; ++i) {
		for (size_t j = i+1; j < buf_len; ++j) {
			for (size_t k = j+1; k < buf_len; ++k) {
				if (buf[i] + buf[j] + buf[k] == 2020) {
					printf("%d", buf[i] * buf[j] * buf[k]);
					return 0;
				}
			}
		}
	}
	return 0;
}
