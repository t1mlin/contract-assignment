import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ChequeBank", function () {
  async function deployChequeBankFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, accounts] = await ethers.getSigners();

    const chequeBank = await ethers.getContractFactory("ChequeBank");

    const chequeBankContract = await chequeBank.deploy();

    await chequeBankContract.deployed();

    return { chequeBankContract, owner, otherAccount, accounts };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { chequeBankContract, owner } = await loadFixture(
        deployChequeBankFixture
      );

      expect(await chequeBankContract.owner()).to.equal(owner.address);
    });

    it("valid signature", async function () {
      const { chequeBankContract, owner, accounts, otherAccount } =
        await loadFixture(deployChequeBankFixture);

      const signer = owner;

      const chequeInfo = {
        amount: 1,
        chequeId: ethers.utils.hexZeroPad(
          "0x74657374000000000000000000000000000000000000000000000000000000",
          32
        ),
        validFrom: 1,
        validThru: 2,
        payee: signer.address,
        payer: signer.address,
        contractAddress: signer.address,
      };

      const hash = await chequeBankContract.getChequeHash({
        chequeInfo,
        sig: "",
      });
      const sig = await signer.signMessage(ethers.utils.arrayify(hash));

      expect(
        await chequeBankContract.isChequeValid(
          signer.address,
          {
            chequeInfo,
            sig,
          },
          sig
        )
      ).to.equal(true);
    });
  });
});
