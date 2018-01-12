pragma solidity ^0.4.18;

//import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
//import "github.com/Arachnid/solidity-stringutils/strings.sol";
import "imports/strings.sol";

contract ManagerContract {
    using strings for *;

    struct Player {
        address _owner;
        string name;
        uint256 salary;
    }
    
    enum CallbackType {
        DelayedPay,
        StatusCheck
    }
    
    enum Status {
        None,
        False,
        True
    }
    
    enum ContractState {
        Created,
        ManagerSigned,
        PlayerSigned,
        AwaitingPayment,
        Paid
    }
    
    address private _owner;
    Player private _player;
    Status private _currentStatus = Status.None;
    ContractState private _currentState = ContractState.Created;

    mapping (bytes32 => CallbackType) private callbacks;
    
    modifier requiresOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    modifier atState(ContractState state) {
        require(_currentState == state);
        _;
    }
    
    function ManagerContract() public {
        _owner = msg.sender;
    }
    
    event ContractSigned(string msg, uint256 salary);
    event FundsTransfered(uint256 funds, uint256 balance);
    event ContractPaid();
    event ContractNotPaid(string msg);
    event NewQuery(string description);
    event NewStatus(string status);
    
    function signContractWithPlayer(address owner, string name, uint256 salary) 
        public 
        requiresOwner
        atState(ContractState.Created) 
    {
        _player = Player(owner, name, salary);
        NewStatus("Contract Signed by Manager");
        
        _currentState = ContractState.ManagerSigned;
    }
    
    function () 
        public 
        payable
    {
        if (_currentState == ContractState.Paid)
            revert();
        
        FundsTransfered(msg.value, this.balance);
    }
    
    function signContractWithManager() 
        public 
        atState(ContractState.ManagerSigned)
    {
        if (msg.sender != _player._owner)
            revert();
        
        if (this.balance < _player.salary)
            revert();
    
        NewStatus("Contract Signed by Player");
        
        _currentState = ContractState.PlayerSigned;
        _currentState = ContractState.AwaitingPayment;
        
        //queueDelayedPay(10 seconds);
    }
    
    function pay() 
        public
        atState(ContractState.AwaitingPayment)
    {
        // if (msg.sender != _owner && msg.sender != oraclize_cbAddress())
        //     revert();

        if (msg.sender != _owner)
            revert();
        
        if (_currentStatus == Status.None) {
            updateStatus();
            return;
        }
        
        // Trying to avoid paing twice by manual payment and delayed payment.
        _currentState = ContractState.Paid;
        
        if (_currentStatus == Status.False) {
            ContractNotPaid("Status == false");
        } else {
            if (this.balance < _player.salary) {
                ContractNotPaid("Insufficient funds");
            } else {
                if (!_player._owner.send(_player.salary)) {
                    ContractNotPaid("Failed to send funds");
                } else {
                    FundsTransfered(_player.salary, this.balance);
                    ContractPaid();
                }
            }
        }
        
        _currentStatus = Status.None;
        _currentState = ContractState.AwaitingPayment;
    }
    
    function closeContract() 
        public
        requiresOwner
    {
        NewStatus("Closing contract");
        selfdestruct(_owner);
    }
    
    function getCurrentState() public constant returns(ContractState) {
        return _currentState;
    }
    
    function __callback(bytes32 myid, string result) public {
        // if (msg.sender != oraclize_cbAddress()) 
        //     revert();
            
        NewStatus("Callback!");
            
        if (callbacks[myid] == CallbackType.DelayedPay) {
            NewStatus("Making delayed pay");
            
            if (_currentStatus == Status.None)
                updateStatus();
            else
                pay();
        } else { 
            // CallbackType.StatusCheck.
            NewStatus(result);

            if (result.toSlice().equals("true".toSlice()))
                _currentStatus = Status.True;
            else
                _currentStatus = Status.False;
                
            if (_currentState == ContractState.AwaitingPayment) {
                pay();
            }
        }
    }
    
    function updateStatus() 
        public 
        payable
    {
        NewQuery("Status query was sent, standing by for the answer..");
        
        //bytes32 queryId = oraclize_query("URL", "json(http://test-blockchain.getsandbox.com/state).state");
        bytes32 queryId = "222";
        callbacks[queryId] = CallbackType.StatusCheck;
        __callback(queryId, "true");
    }
    
    function queueDelayedPay(uint delay) 
        public 
        payable 
        atState(ContractState.AwaitingPayment)
    {
        NewQuery("Queueing delayed pay...");
        
        //bytes32 queryId = oraclize_query(delay, "URL", "");
        bytes32 queryId = "123";
        callbacks[queryId] = CallbackType.DelayedPay;
        __callback(queryId, "");
    }
}