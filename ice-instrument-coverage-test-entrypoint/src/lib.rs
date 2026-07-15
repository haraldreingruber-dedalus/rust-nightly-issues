#![cfg_attr(coverage_nightly, feature(coverage_attribute))]

use mockall_double::double;

mod real_pool {
    use mockall::automock;

    pub struct Pool;

    #[cfg_attr(test, automock)]
    impl Pool {
        pub fn get(&self) -> u32 { 1 }
    }
}

#[double]
use real_pool::Pool;

pub struct Consumer {
    id: usize,
}

impl Consumer {
    pub fn new(id: usize) -> Self { Self { id } }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;

    #[test]
    #[serial]
    fn test_consumer_new() {
        let c = Consumer::new(42);
        assert_eq!(c.id, 42);
    }

    #[test]
    #[serial]
    fn test_pool_get() {
        let mut pool = Pool::new();
        pool.expect_get().returning(|| 99);
        assert_eq!(pool.get(), 99);
    }
}
