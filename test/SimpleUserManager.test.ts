import { expect } from "chai";
import { network } from "hardhat";

describe("SimpleUserManager - TypeScript Tests", function () {
  let userManager: any;
  let deployer: any;
  let user1: any;
  let user2: any;
  let user3: any;
  let user4: any;

  // Datos de prueba para usuarios
  const USER1_DATA = {
    username: "testuser1",
    email: "test1@example.com",
    twitterLink: "https://twitter.com/testuser1",
    githubLink: "https://github.com/testuser1",
    telegramLink: "https://t.me/testuser1",
    avatarLink: "https://example.com/avatar1.jpg",
    coverImageLink: "https://example.com/cover1.jpg"
  };

  const USER2_DATA = {
    username: "testuser2",
    email: "test2@example.com",
    twitterLink: "https://twitter.com/testuser2",
    githubLink: "https://github.com/testuser2",
    telegramLink: "https://t.me/testuser2",
    avatarLink: "https://example.com/avatar2.jpg",
    coverImageLink: "https://example.com/cover2.jpg"
  };

  const USER3_DATA = {
    username: "testuser3",
    email: "test3@example.com",
    twitterLink: "https://twitter.com/testuser3",
    githubLink: "https://github.com/testuser3",
    telegramLink: "https://t.me/testuser3",
    avatarLink: "https://example.com/avatar3.jpg",
    coverImageLink: "https://example.com/cover3.jpg"
  };

  beforeEach(async function () {
    const { ethers } = await network.connect();
    [deployer, user1, user2, user3, user4] = await ethers.getSigners();
    
    // Desplegar contrato SimpleUserManager
    const SimpleUserManagerFactory = await ethers.getContractFactory("SimpleUserManager");
    userManager = await SimpleUserManagerFactory.deploy();
    await userManager.waitForDeployment();
  });

  describe("Constructor y Estado Inicial", function () {
    it("Debería desplegar el contrato correctamente", async function () {
      expect(await userManager.getAddress()).to.be.properAddress;
    });

    it("Debería tener 0 usuarios registrados inicialmente", async function () {
      expect(await userManager.getTotalMembers()).to.equal(0);
    });

    it("Debería retornar array vacío de usuarios inicialmente", async function () {
      const allUsers = await userManager.getAllUsers();
      expect(allUsers).to.be.an('array');
      expect(allUsers.length).to.equal(0);
    });

    it("Debería retornar false para usuario no registrado", async function () {
      expect(await userManager.isRegisteredUser(user1.address)).to.be.false;
    });
  });

  describe("Registro de Usuarios", function () {
    it("Debería permitir registrar un usuario con todos los datos", async function () {
      await expect(
        userManager.connect(user1).registerUser(
          USER1_DATA.username,
          USER1_DATA.email,
          USER1_DATA.twitterLink,
          USER1_DATA.githubLink,
          USER1_DATA.telegramLink,
          USER1_DATA.avatarLink,
          USER1_DATA.coverImageLink
        )
      ).to.emit(userManager, "UserRegistered")
        .withArgs(user1.address);

      expect(await userManager.isRegisteredUser(user1.address)).to.be.true;
      expect(await userManager.getTotalMembers()).to.equal(1);
    });

    it("Debería almacenar correctamente toda la información del usuario", async function () {
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      const userInfo = await userManager.getUserInfo(user1.address);
      expect(userInfo.username).to.equal(USER1_DATA.username);
      expect(userInfo.userAddress).to.equal(user1.address);
      expect(userInfo.email).to.equal(USER1_DATA.email);
      expect(userInfo.twitterLink).to.equal(USER1_DATA.twitterLink);
      expect(userInfo.githubLink).to.equal(USER1_DATA.githubLink);
      expect(userInfo.telegramLink).to.equal(USER1_DATA.telegramLink);
      expect(userInfo.avatarLink).to.equal(USER1_DATA.avatarLink);
      expect(userInfo.coverImageLink).to.equal(USER1_DATA.coverImageLink);
      expect(userInfo.joinTimestamp).to.be.greaterThan(0);
    });

    it("Debería establecer correctamente el timestamp de registro", async function () {
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      const userInfo = await userManager.getUserInfo(user1.address);
      
      // Verificar que el timestamp es mayor que 0 y razonable
      expect(userInfo.joinTimestamp).to.be.greaterThan(0);
      expect(userInfo.joinTimestamp).to.be.lessThan(Math.floor(Date.now() / 1000) + 10);
    });

    it("Debería permitir registrar múltiples usuarios", async function () {
      // Registrar user1
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      // Registrar user2
      await userManager.connect(user2).registerUser(
        USER2_DATA.username,
        USER2_DATA.email,
        USER2_DATA.twitterLink,
        USER2_DATA.githubLink,
        USER2_DATA.telegramLink,
        USER2_DATA.avatarLink,
        USER2_DATA.coverImageLink
      );

      expect(await userManager.isRegisteredUser(user1.address)).to.be.true;
      expect(await userManager.isRegisteredUser(user2.address)).to.be.true;
      expect(await userManager.getTotalMembers()).to.equal(2);

      const allUsers = await userManager.getAllUsers();
      expect(allUsers).to.include(user1.address);
      expect(allUsers).to.include(user2.address);
    });

    it("Debería revertir si un usuario ya está registrado", async function () {
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      await expect(
        userManager.connect(user1).registerUser(
          "anotherusername",
          "another@example.com",
          "https://twitter.com/another",
          "https://github.com/another",
          "https://t.me/another",
          "https://example.com/avatar2.jpg",
          "https://example.com/cover2.jpg"
        )
      ).to.be.revertedWithCustomError(userManager, "UserAlreadyExists")
        .withArgs(user1.address);
    });

    it("Debería permitir registrar usuarios con strings vacíos", async function () {
      await userManager.connect(user1).registerUser(
        "", // username vacío
        "", // email vacío
        "", // twitter vacío
        "", // github vacío
        "", // telegram vacío
        "", // avatar vacío
        ""  // cover vacío
      );

      expect(await userManager.isRegisteredUser(user1.address)).to.be.true;
    });
  });

  describe("Actualización de Información de Usuario", function () {
    beforeEach(async function () {
      // Registrar usuario para las pruebas de actualización
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );
    });

    it("Debería permitir actualizar toda la información del usuario", async function () {
      const newEmail = "newemail@example.com";
      const newTwitter = "https://twitter.com/newuser";
      const newGithub = "https://github.com/newuser";
      const newTelegram = "https://t.me/newuser";
      const newAvatar = "https://example.com/newavatar.jpg";
      const newCover = "https://example.com/newcover.jpg";

      await expect(
        userManager.connect(user1).updateUserInfo(
          newEmail,
          newTwitter,
          newGithub,
          newTelegram,
          newAvatar,
          newCover
        )
      ).to.emit(userManager, "UserInfoUpdated")
        .withArgs(user1.address);

      const userInfo = await userManager.getUserInfo(user1.address);
      expect(userInfo.email).to.equal(newEmail);
      expect(userInfo.twitterLink).to.equal(newTwitter);
      expect(userInfo.githubLink).to.equal(newGithub);
      expect(userInfo.telegramLink).to.equal(newTelegram);
      expect(userInfo.avatarLink).to.equal(newAvatar);
      expect(userInfo.coverImageLink).to.equal(newCover);
    });

    it("Debería mantener el username y timestamp originales", async function () {
      const originalInfo = await userManager.getUserInfo(user1.address);
      const originalUsername = originalInfo.username;
      const originalTimestamp = originalInfo.joinTimestamp;

      await userManager.connect(user1).updateUserInfo(
        "newemail@example.com",
        "https://twitter.com/newuser",
        "https://github.com/newuser",
        "https://t.me/newuser",
        "https://example.com/newavatar.jpg",
        "https://example.com/newcover.jpg"
      );

      const updatedInfo = await userManager.getUserInfo(user1.address);
      expect(updatedInfo.username).to.equal(originalUsername);
      expect(updatedInfo.joinTimestamp).to.equal(originalTimestamp);
    });

    it("Debería revertir si el usuario no está registrado", async function () {
      await expect(
        userManager.connect(user2).updateUserInfo(
          "newemail@example.com",
          "https://twitter.com/newuser",
          "https://github.com/newuser",
          "https://t.me/newuser",
          "https://example.com/newavatar.jpg",
          "https://example.com/newcover.jpg"
        )
      ).to.be.revertedWithCustomError(userManager, "UserNotRegistered")
        .withArgs(user2.address);
    });

    it("Debería permitir actualizar solo algunos campos", async function () {
      const newEmail = "newemail@example.com";
      const newAvatar = "https://example.com/newavatar.jpg";

      await userManager.connect(user1).updateUserInfo(
        newEmail,
        USER1_DATA.twitterLink, // mantener original
        USER1_DATA.githubLink,  // mantener original
        USER1_DATA.telegramLink, // mantener original
        newAvatar,
        USER1_DATA.coverImageLink // mantener original
      );

      const userInfo = await userManager.getUserInfo(user1.address);
      expect(userInfo.email).to.equal(newEmail);
      expect(userInfo.avatarLink).to.equal(newAvatar);
      expect(userInfo.twitterLink).to.equal(USER1_DATA.twitterLink);
      expect(userInfo.githubLink).to.equal(USER1_DATA.githubLink);
    });
  });

  describe("Eliminación de Usuarios", function () {
    beforeEach(async function () {
      // Registrar múltiples usuarios para las pruebas de eliminación
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      await userManager.connect(user2).registerUser(
        USER2_DATA.username,
        USER2_DATA.email,
        USER2_DATA.twitterLink,
        USER2_DATA.githubLink,
        USER2_DATA.telegramLink,
        USER2_DATA.avatarLink,
        USER2_DATA.coverImageLink
      );

      await userManager.connect(user3).registerUser(
        USER3_DATA.username,
        USER3_DATA.email,
        USER3_DATA.twitterLink,
        USER3_DATA.githubLink,
        USER3_DATA.telegramLink,
        USER3_DATA.avatarLink,
        USER3_DATA.coverImageLink
      );
    });

    it("Debería permitir eliminar un usuario registrado", async function () {
      expect(await userManager.getTotalMembers()).to.equal(3);
      expect(await userManager.isRegisteredUser(user1.address)).to.be.true;

      await expect(
        userManager.connect(user1).removeUser()
      ).to.emit(userManager, "UserRemoved")
        .withArgs(user1.address);

      expect(await userManager.isRegisteredUser(user1.address)).to.be.false;
      expect(await userManager.getTotalMembers()).to.equal(2);
    });

    it("Debería eliminar correctamente al usuario del array de direcciones", async function () {
      let allUsers = await userManager.getAllUsers();
      expect(allUsers).to.include(user1.address);

      await userManager.connect(user1).removeUser();

      allUsers = await userManager.getAllUsers();
      expect(allUsers).to.not.include(user1.address);
      expect(allUsers).to.include(user2.address);
      expect(allUsers).to.include(user3.address);
    });

    it("Debería revertir si el usuario no está registrado", async function () {
      await expect(
        userManager.connect(user4).removeUser()
      ).to.be.revertedWithCustomError(userManager, "UserNotRegistered")
        .withArgs(user4.address);
    });

    it("Debería permitir eliminar usuarios del medio del array", async function () {
      // Eliminar user2 (que está en el medio)
      await userManager.connect(user2).removeUser();

      expect(await userManager.isRegisteredUser(user2.address)).to.be.false;
      expect(await userManager.getTotalMembers()).to.equal(2);

      const allUsers = await userManager.getAllUsers();
      expect(allUsers).to.include(user1.address);
      expect(allUsers).to.not.include(user2.address);
      expect(allUsers).to.include(user3.address);
    });

    it("Debería permitir registrar un usuario después de eliminarlo", async function () {
      // Eliminar user1
      await userManager.connect(user1).removeUser();
      expect(await userManager.isRegisteredUser(user1.address)).to.be.false;

      // Registrar user1 nuevamente
      await userManager.connect(user1).registerUser(
        "newusername",
        "newemail@example.com",
        "https://twitter.com/newuser",
        "https://github.com/newuser",
        "https://t.me/newuser",
        "https://example.com/newavatar.jpg",
        "https://example.com/newcover.jpg"
      );

      expect(await userManager.isRegisteredUser(user1.address)).to.be.true;
      expect(await userManager.getTotalMembers()).to.equal(3);
    });
  });

  describe("Funciones de Consulta", function () {
    beforeEach(async function () {
      // Registrar usuarios para las pruebas de consulta
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      await userManager.connect(user2).registerUser(
        USER2_DATA.username,
        USER2_DATA.email,
        USER2_DATA.twitterLink,
        USER2_DATA.githubLink,
        USER2_DATA.telegramLink,
        USER2_DATA.avatarLink,
        USER2_DATA.coverImageLink
      );
    });

    it("Debería retornar correctamente el estado de registro", async function () {
      expect(await userManager.isRegisteredUser(user1.address)).to.be.true;
      expect(await userManager.isRegisteredUser(user2.address)).to.be.true;
      expect(await userManager.isRegisteredUser(user3.address)).to.be.false;
    });

    it("Debería retornar la información completa del usuario", async function () {
      const userInfo = await userManager.getUserInfo(user1.address);
      
      expect(userInfo.username).to.equal(USER1_DATA.username);
      expect(userInfo.userAddress).to.equal(user1.address);
      expect(userInfo.email).to.equal(USER1_DATA.email);
      expect(userInfo.twitterLink).to.equal(USER1_DATA.twitterLink);
      expect(userInfo.githubLink).to.equal(USER1_DATA.githubLink);
      expect(userInfo.telegramLink).to.equal(USER1_DATA.telegramLink);
      expect(userInfo.avatarLink).to.equal(USER1_DATA.avatarLink);
      expect(userInfo.coverImageLink).to.equal(USER1_DATA.coverImageLink);
      expect(userInfo.joinTimestamp).to.be.greaterThan(0);
    });

    it("Debería retornar todas las direcciones de usuarios registrados", async function () {
      const allUsers = await userManager.getAllUsers();
      
      expect(allUsers).to.be.an('array');
      expect(allUsers.length).to.equal(2);
      expect(allUsers).to.include(user1.address);
      expect(allUsers).to.include(user2.address);
    });

    it("Debería retornar el número correcto de miembros", async function () {
      expect(await userManager.getTotalMembers()).to.equal(2);

      // Registrar un usuario más
      await userManager.connect(user3).registerUser(
        USER3_DATA.username,
        USER3_DATA.email,
        USER3_DATA.twitterLink,
        USER3_DATA.githubLink,
        USER3_DATA.telegramLink,
        USER3_DATA.avatarLink,
        USER3_DATA.coverImageLink
      );

      expect(await userManager.getTotalMembers()).to.equal(3);
    });

    it("Debería revertir al consultar información de usuario no registrado", async function () {
      await expect(
        userManager.getUserInfo(user3.address)
      ).to.be.revertedWithCustomError(userManager, "UserNotRegistered")
        .withArgs(user3.address);
    });
  });

  describe("Casos Límite y Validaciones", function () {
    it("Debería manejar strings muy largos", async function () {
      const longString = "A".repeat(1000); // 1000 caracteres

      await userManager.connect(user1).registerUser(
        longString,
        longString,
        longString,
        longString,
        longString,
        longString,
        longString
      );

      const userInfo = await userManager.getUserInfo(user1.address);
      expect(userInfo.username).to.equal(longString);
      expect(userInfo.email).to.equal(longString);
    });

    it("Debería manejar caracteres especiales en strings", async function () {
      const specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?`~";

      await userManager.connect(user1).registerUser(
        specialChars,
        specialChars,
        specialChars,
        specialChars,
        specialChars,
        specialChars,
        specialChars
      );

      const userInfo = await userManager.getUserInfo(user1.address);
      expect(userInfo.username).to.equal(specialChars);
    });

    it("Debería mantener consistencia después de múltiples operaciones", async function () {
      // Registrar usuarios
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      await userManager.connect(user2).registerUser(
        USER2_DATA.username,
        USER2_DATA.email,
        USER2_DATA.twitterLink,
        USER2_DATA.githubLink,
        USER2_DATA.telegramLink,
        USER2_DATA.avatarLink,
        USER2_DATA.coverImageLink
      );

      // Actualizar información
      await userManager.connect(user1).updateUserInfo(
        "updated@example.com",
        "https://twitter.com/updated",
        "https://github.com/updated",
        "https://t.me/updated",
        "https://example.com/updatedavatar.jpg",
        "https://example.com/updatedcover.jpg"
      );

      // Eliminar un usuario
      await userManager.connect(user2).removeUser();

      // Verificar consistencia
      expect(await userManager.getTotalMembers()).to.equal(1);
      expect(await userManager.isRegisteredUser(user1.address)).to.be.true;
      expect(await userManager.isRegisteredUser(user2.address)).to.be.false;

      const allUsers = await userManager.getAllUsers();
      expect(allUsers.length).to.equal(1);
      expect(allUsers[0]).to.equal(user1.address);

      const userInfo = await userManager.getUserInfo(user1.address);
      expect(userInfo.email).to.equal("updated@example.com");
    });
  });

  describe("Tests de Gas", function () {
    it("Debería reportar uso de gas para registro de usuario", async function () {
      const tx = await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );
      
      const receipt = await tx.wait();
      console.log(`Gas usado para registrar usuario: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });

    it("Debería reportar uso de gas para actualización de usuario", async function () {
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      const tx = await userManager.connect(user1).updateUserInfo(
        "newemail@example.com",
        "https://twitter.com/newuser",
        "https://github.com/newuser",
        "https://t.me/newuser",
        "https://example.com/newavatar.jpg",
        "https://example.com/newcover.jpg"
      );
      
      const receipt = await tx.wait();
      console.log(`Gas usado para actualizar usuario: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });

    it("Debería reportar uso de gas para eliminación de usuario", async function () {
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      const tx = await userManager.connect(user1).removeUser();
      const receipt = await tx.wait();
      console.log(`Gas usado para eliminar usuario: ${receipt?.gasUsed.toString()}`);
      expect(receipt?.gasUsed).to.be.greaterThan(0);
    });
  });

  describe("Eventos", function () {
    it("Debería emitir evento UserRegistered al registrar usuario", async function () {
      await expect(
        userManager.connect(user1).registerUser(
          USER1_DATA.username,
          USER1_DATA.email,
          USER1_DATA.twitterLink,
          USER1_DATA.githubLink,
          USER1_DATA.telegramLink,
          USER1_DATA.avatarLink,
          USER1_DATA.coverImageLink
        )
      ).to.emit(userManager, "UserRegistered")
        .withArgs(user1.address);
    });

    it("Debería emitir evento UserInfoUpdated al actualizar información", async function () {
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      await expect(
        userManager.connect(user1).updateUserInfo(
          "newemail@example.com",
          "https://twitter.com/newuser",
          "https://github.com/newuser",
          "https://t.me/newuser",
          "https://example.com/newavatar.jpg",
          "https://example.com/newcover.jpg"
        )
      ).to.emit(userManager, "UserInfoUpdated")
        .withArgs(user1.address);
    });

    it("Debería emitir evento UserRemoved al eliminar usuario", async function () {
      await userManager.connect(user1).registerUser(
        USER1_DATA.username,
        USER1_DATA.email,
        USER1_DATA.twitterLink,
        USER1_DATA.githubLink,
        USER1_DATA.telegramLink,
        USER1_DATA.avatarLink,
        USER1_DATA.coverImageLink
      );

      await expect(
        userManager.connect(user1).removeUser()
      ).to.emit(userManager, "UserRemoved")
        .withArgs(user1.address);
    });
  });
});
