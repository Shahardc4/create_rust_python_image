use rayon::prelude::*;
fn main() {
    let vec = vec![1, 2, 3, 4, 5];

    vec.into_par_iter().try_for_each(|x| {
        println!("{}", x * x);
        Ok::<(), ()>(())
    }).unwrap();
}
