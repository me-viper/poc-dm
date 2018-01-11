var playerAccount = "0xf17f52151EbEF6C7334FAD080c5704D77216b732";

var mc;

ManagerContract.deployed().then(inst => {
    mc = inst;
    mc.signContractWithPlayer.call(playerAccount, "Some Player", 5).then(r => {
        console.log(r);
        mc.getCurrentStatus.call().then(rr => console.log(rr));
    });
});