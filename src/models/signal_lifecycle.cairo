#[derive(Copy, Drop, Serde, Debug, PartialEq)]
enum SignalStatus {
    Open,
    Validated,
    Expired,
    Disputed,
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct SignalLifecycle {
    #[key]
    pub signal_id: u256,
    pub status: SignalStatus,
    pub created_at: u64,
    pub updated_at: u64,
    pub expires_at: u64,
}
