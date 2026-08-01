/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // add up queries...
  const email = "guest@example.com";
  const password = "guest1234";
  let user = null;

  try{
    user = app.findAuthRecordByEmail("users", email);
  }catch(e){

  }

  if (!user) {
    const usersCollection = app.findCollectionByNameOrId("users");
    user = new Record(usersCollection);
    user.set("email", email);
    user.set("password", password);
    user.set("passwordConfirm", password);
    user.set("verified", true);
    user.set("name", "Guest");

    app.save(user);
  }


}, (app) => {
  // add down queries...
})
