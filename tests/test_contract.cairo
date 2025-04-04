use counter::counter::{Counter, ICounterDispatcher, ICounterDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::ContractAddress;

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
    assert!(
        initial_counter == counter.get_counter(),
        "Expected {} found this {}",
        initial_counter,
        counter.get_counter(),
    );
}

#[test]
fn test_increase_counter() {
    let initial_counter: u64 = 2;
    let contract_address = deploy_contract(initial_counter);
    let counter = ICounterDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    counter.increase_counter(30);
    stop_cheat_caller_address(contract_address);
    assert!(
        counter.get_counter() == 32,
        "Expected {} found this {}",
        initial_counter,
        counter.get_counter(),
    );
}

#[test]
fn test_decrease_counter() {
    let initial_counter: u64 = 10;
    let contract_address = deploy_contract(initial_counter);
    let counter = ICounterDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    counter.decrease_counter(3);
    stop_cheat_caller_address(contract_address);
    assert!(counter.get_counter() == 7, "Expected 7 found this {}", counter.get_counter());
}

#[test]
#[should_panic(expected: 'Counter cannot be less than 0')]
fn test_decrease_counter_should_panic() {
    let initial_counter: u64 = 0;
    let contract_address = deploy_contract(initial_counter);
    let counter = ICounterDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    counter.decrease_counter(1);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_increase_counter_event() {
    let initial_counter: u64 = 10;
    let contract_address = deploy_contract(initial_counter);
    let counter = ICounterDispatcher { contract_address };
    let mut spy = spy_events();
    start_cheat_caller_address(contract_address, OWNER());
    counter.increase_counter(10);
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Counter::Event::CounterIncreased(Counter::CounterIncreased { counter: 20 }),
                ),
            ],
        );
    stop_cheat_caller_address(contract_address);
}
