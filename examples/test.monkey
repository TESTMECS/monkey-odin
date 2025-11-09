#!/usr/bin/env monkey -- 


#!/usr/bin/env monkey -- classes-refactored
let my_class = class() {
    let new = fn(self) {
        self.x = 10;
        self.y = 20;
    };
};

let a = my_class();
a->new();


