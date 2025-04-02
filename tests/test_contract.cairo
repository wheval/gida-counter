use starknet::{ContractAddress};

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};

use counter::counter::{ICounterDispatcher, ICounterDispatcherTrait};

pub fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}
pub fn WHEVAL() -> ContractAddress {
    'WHEVAL'.try_into().unwrap()
}

fn deploy_contract(initial_counter: u64) -> ContractAddress {
    let class_hash = declare("Counter").unwrap().contract_class();
    let mut calldata = array![];
    initial_counter.serialize(ref calldata);
    OWNER().serialize(ref calldata);
    let (contract_address, _) = class_hash.deploy(@calldata).unwrap();
    contract_address  
}

#[test]
fn test_initial_counter() {
    let initial_counter: u64 = 20;
    let contract_address = deploy_contract(initial_counter);
    let counter = ICounterDispatcher { contract_address };
    assert!(initial_counter == counter.get_counter(), "Expected {} found this {}", initial_counter, counter.get_counter());
}

#[test]
fn test_increase_counter() {
    let initial_counter: u64 = 2;
    let contract_address = deploy_contract(initial_counter);
    let counter = ICounterDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    counter.increase_counter(30);
    stop_cheat_caller_address(contract_address);
    assert!(counter.get_counter() == 32, "Expected {} found this {}", initial_counter, counter.get_counter());
}

// #[test]
// fn test_decrease_counter {

// }