use dojo_cairo_test::{
    ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
    spawn_test_world,
};
use dojo::world::{WorldStorage, WorldStorageTrait};

use onchainsage::models::signal::{m_Signal, m_Signals, m_SignalCount, m_SignalValidator};
use onchainsage::models::auth::m_Auth;
use onchainsage::systems::signal::{signal_system};
use onchainsage::systems::auth::{auth_system};

pub fn namespace_def() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "onchainsage",
        resources: [
            TestResource::Model(m_Signal::TEST_CLASS_HASH),
            TestResource::Model(m_Signals::TEST_CLASS_HASH),
            TestResource::Model(m_SignalCount::TEST_CLASS_HASH),
            TestResource::Model(m_SignalValidator::TEST_CLASS_HASH),
            TestResource::Model(m_Auth::TEST_CLASS_HASH),
            TestResource::Event(signal_system::e_SignalGenerated::TEST_CLASS_HASH),
            TestResource::Event(signal_system::e_SignalValidated::TEST_CLASS_HASH),
            TestResource::Event(auth_system::e_RoleGranted::TEST_CLASS_HASH),
            TestResource::Event(auth_system::e_RoleRevoked::TEST_CLASS_HASH),
            TestResource::Contract(signal_system::TEST_CLASS_HASH),
            TestResource::Contract(auth_system::TEST_CLASS_HASH),
        ]
            .span(),
    };

    ndef
}

pub fn contract_defs() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"onchainsage", @"signal_system")
            .with_writer_of([dojo::utils::bytearray_hash(@"onchainsage")].span()),
        ContractDefTrait::new(@"onchainsage", @"auth_system")
            .with_writer_of([dojo::utils::bytearray_hash(@"onchainsage")].span()),
    ]
        .span()
}

pub fn setup() -> WorldStorage {
    let ndef = namespace_def();
    let mut world: WorldStorage = spawn_test_world([ndef].span());
    world.sync_perms_and_inits(contract_defs());

    world
}