var managerAccount = web3.eth.accounts[0];
var playerAccount = web3.eth.accounts[1]; //"0xf17f52151EbEF6C7334FAD080c5704D77216b732";

console.log(managerAccount);
console.log(playerAccount);

var mc;
ManagerContract.deployed().then(inst => mc = inst);
mc.getCurrentState();
mc.send(web3.toWei(10, "ether"));
mc.signContractWithPlayer(playerAccount, "Some Player", web3.toWei(7, "ether"), {from: managerAccount});

web3.eth.getBalance(mc.address);

mc.getCurrentState();
mc.signContractWithManager({from: playerAccount});
