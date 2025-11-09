#!/usr/bin/env monkey-odin --

puts("Bubble Sort!")
let bubble_sort = fn(arr) {
    let n = len(arr);
    let i = 0;

    for (i < n) {
        let j = 0;
        for (j < n - i - 1) {
            if (arr[j] > arr[j + 1]) {
                let tmp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = tmp;
            }
            j = j + 1;
        }
        i = i + 1;
    }
    return arr;
};
puts(bubble_sort([5, 1, 4, 2, 8]));
