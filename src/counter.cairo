#[starknet::interface]
pub trait ICounter<TContractState> {
    /// Increase counter
    fn increase_counter(ref self: TContractState, amount: u64);
    fn decrease_counter(ref self: TContractState, amount: u64);
    /// Retrieve counter
    fn get_counter(self: @TContractState) -> u64;
}

/// Simple contract for counting.
#[starknet::contract]
pub mod Counter {
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::ContractAddress;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u64,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[constructor]
    fn constructor (ref self: ContractState, initial_counter: u64, owner: ContractAddress) {
        self.counter.write(initial_counter);
        self.ownable.initializer(owner);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncreased: CounterIncreased,
        CounterDecreased: CounterDecreased,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }
    
    #[derive(Drop, starknet::Event)]
    pub struct CounterIncreased {
        pub counter: u64
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterDecreased {
        pub counter: u64
    }


    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn increase_counter(ref self: ContractState, amount: u64) {
            self.ownable.assert_only_owner();
            assert(amount != 0, 'Amount cannot be 0');
            assert!(amount < 0, "Amount cannot be less than zero");
            self.counter.write(self.counter.read() + amount);
            self.emit(Event::CounterIncreased(CounterIncreased { counter: self.counter.read() }));
        }
        
        fn get_counter(self: @ContractState) -> u64 {
            self.counter.read()
        }
        fn decrease_counter(ref self: ContractState, amount: u64) {
            self.ownable.assert_only_owner();
            assert(self.counter.read() > 0, 'Counter cannot be less than 0');
            assert!(self.counter.read() > amount, "Amount {} is greater than counter {}", amount, self.counter.read());
            self.counter.write(self.counter.read() - amount);
            self.emit(Event::CounterDecreased(CounterDecreased { counter: self.counter.read() }));
        }
    }
}
