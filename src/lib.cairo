mod models {
    pub mod auth;
    pub mod signal;
}

mod systems {
    pub mod auth;
    pub mod signal;
}

mod events {
    pub mod auth;
    pub mod signal;
}

#[cfg(test)]
mod tests {
    mod auth_test;
    mod test_signal;
}


