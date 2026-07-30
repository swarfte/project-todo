/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const email = "admin@example.com";
    const password = "admin1234";

    // 如果已經存在相同 email 的 Superuser，就不重複建立。
    try {
        const existingSuperuser = app.findAuthRecordByEmail(
            "_superusers",
            email
        );

        if (existingSuperuser) {
            console.log(
                "Dashboard superuser already exists:",
                email
            );

            return;
        }
    } catch (_) {
        // 找不到 Record 時，PocketBase 會拋出錯誤。
        // 在這裡繼續建立新的 Superuser。
    }

    const collection = app.findCollectionByNameOrId(
        "_superusers"
    );

    const superuser = new Record(collection);

    // 固定 ID 令 down migration 只刪除這個 migration 建立的帳戶。
    // PocketBase ID 必須是 15 個小寫英文字母或數字。
    superuser.set(
        "id",
        "sysadmin0000001"
    );

    superuser.setEmail(email);
    superuser.setPassword(password);
    superuser.setVerified(true);

    app.save(superuser);

    console.log(
        "Dashboard superuser created:",
        email
    );
}, (app) => {
    const superuserId = "sysadmin0000001";

    try {
        const superuser = app.findRecordById(
            "_superusers",
            superuserId
        );

        app.delete(superuser);

        console.log(
            "Dashboard superuser removed:",
            superuserId
        );
    } catch (_) {
        // Record 可能本來就不存在，回滾不需要因此失敗。
        console.log(
            "Dashboard superuser not found; nothing to remove."
        );
    }
});
