pragma solidity ^0.4.18;

//import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

contract ManagerContract {
    struct Player {
        address owner;
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
    
    address public owner;
    Player public player;
    Status public currentStatus = Status.None;
    ContractState public currentState;
    
    mapping (bytes32 => CallbackType) private callbacks;
    
    modifier requiesOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier atState(ContractState state) {
        require(currentState == state);
        _;
    }
    
    function ManagerContract() public {
        owner = msg.sender;
        currentState = ContractState.Created;
    }
    
    event contractSigned(string msg, uint256 salary);
    event fundsTransfered(uint256 funds, uint256 balance);
    event contractPaid();
    event contractNotPaid(string msg);
    event newQuery(string description);
    event newStatus(string status);
    
    function signContractWithPlayer(address _owner, string _name, uint256 _salary) 
        public 
        requiesOwner
        atState(ContractState.Created) 
    {
        player = Player(_owner, _name, _salary);
        newStatus("Contract Signed by Manager");
        
        currentState = ContractState.ManagerSigned;
    }
    
    function () 
        public 
        payable
    {
        if (currentState == ContractState.Paid)
            revert();
        
        fundsTransfered(msg.value, this.balance);
    }
    
    function signContractWithManager() 
        public 
        //atState(ContractState.ManagerSigned)
    {
        // if (msg.sender != player.owner)
        //     revert();
        
        // if (this.balance < player.salary)
        //     revert();
    
        newStatus("Contract Signed by Player");
        
        currentState = ContractState.PlayerSigned;
        currentState = ContractState.AwaitingPayment;
        
        //queueDelayedPay(10 seconds);
    }
    
    function pay() 
        public
        atState(ContractState.AwaitingPayment)
    {
        // if (msg.sender != owner && msg.sender != oraclize_cbAddress())
        //     revert();
        
        if (currentStatus == Status.None) {
            updateStatus();
            return;
        }
        
        // Trying to avoid paing twice by manual payment and delayed payment.
        currentState = ContractState.Paid;
        
        if (currentStatus == Status.False) {
            contractNotPaid("Status == false");
        } else {
            if (this.balance < player.salary) {
                contractNotPaid("Insufficient funds");
            } else {
                if (!player.owner.send(player.salary)) {
                    contractNotPaid("Failed to send funds");
                } else {
                    fundsTransfered(player.salary, this.balance);
                    contractPaid();
                }
            }
        }
        
        currentStatus = Status.None;
        currentState = ContractState.AwaitingPayment;
    }
    
    function closeContract() 
        public
        requiesOwner
    {
        newStatus("Closing contract");
        selfdestruct(owner);
    }
    
    function getCurrentState() public constant returns(ContractState) {
        return currentState;
    }
    
    function callback(bytes32 myid, int result) public {
        // if (msg.sender != oraclize_cbAddress()) 
        //     revert();
            
        newStatus("Callback!");
            
        if (callbacks[myid] == CallbackType.DelayedPay) {
            newStatus("Making delayed pay");
            
            if (currentStatus == Status.None)
                updateStatus();
            else
                pay();
        } else { 
            // CallbackType.StatusCheck.
            // newStatus(result);
            
            if (result == 1)
                currentStatus = Status.True;
            else
                currentStatus = Status.False;
                
            if (currentState == ContractState.AwaitingPayment) {
                pay();
            }
        }
    }
    
    function updateStatus() 
        public 
        payable 
    {
        newQuery("Status query was sent, standing by for the answer..");
        
        //bytes32 queryId = oraclize_query("URL", "json(http://test-blockchain.getsandbox.com/state).state");
        bytes32 queryId = "222";
        callbacks[queryId] = CallbackType.StatusCheck;
        callback(queryId, 1);
    }
    
    function queueDelayedPay(uint _delay) 
        public 
        payable 
        atState(ContractState.AwaitingPayment)
    {
        newQuery("Queueing delayed pay...");
        
        //bytes32 queryId = oraclize_query(_delay, "URL", "");
        bytes32 queryId = "123";
        callbacks[queryId] = CallbackType.DelayedPay;
        callback(queryId, 0);
    }
}