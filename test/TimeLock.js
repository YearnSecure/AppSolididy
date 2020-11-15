const TestToken = artifacts.require("TestToken");
const TimeLock = artifacts.require("ERC20Timelock");

contract('TestToken', (accounts) =>{
    it('Initial should be 1000000 ', async () =>{
        const TestTokenInstance = await TestToken.deployed();
        const totalSupply = await TestTokenInstance.totalSupply();
        const balance = await TestTokenInstance.balanceOf.call(accounts[0]);
        assert.equal(balance.valueOf(), 1000000 * Math.pow(10, 18), "1000000 wasn't in the first account");
        assert.equal(totalSupply.valueOf(), 1000000 * Math.pow(10, 18), "Total supply is not 1000000");
    });
});

contract('ERC20TimeLock', (accounts) =>{
    it('CheckInit', async() =>{
        const TestTokenInstance = await TestToken.deployed();
        const TimeLockInstance = await TimeLock.deployed();

        const TimeLockTokenOwnerAddress = await TimeLockInstance.TokenOwner.call();
        assert.equal(accounts[0], TimeLockTokenOwnerAddress, "TokenOwner of contract is not set correctly!");
        const TimeLockTokenAddress = await TimeLockInstance.TokenAddress.call();
        assert.equal(TestTokenInstance.address, TimeLockTokenAddress, "TokenAddress of contract is not set correctly!");
    });

    it('CheckAddAllowanceWithNoApproval', async() =>{
        const TestTokenInstance = await TestToken.deployed();
        const TimeLockInstance = await TimeLock.deployed();
        try{
            await TimeLockInstance.AddAllocation("test", 1000, 0, 0, false, 0, 0);
        }
        catch(err){
            assert.include(err.message, "Transfer of token has not been approved", "The error message should contain 'Transfer of token has not been approved'");
        }
    });

    it('CheckAddAllowanceWithApproval', async() =>{
        const TestTokenInstance = await TestToken.deployed();
        const TimeLockInstance = await TimeLock.deployed();
        
        await TestTokenInstance.approve(TimeLockInstance.address, 1000);
        await TimeLockInstance.AddAllocation("test", 1000, 0, 0, false, 0, 0);
        const balanceOnTimeLock = await TestTokenInstance.balanceOf.call(TimeLockInstance.address);
        assert.equal(balanceOnTimeLock, 1000, "Balance on timelock contract should be 1000")
    });
});