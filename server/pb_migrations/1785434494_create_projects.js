/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = new Collection({
        id: "pbc_1901958808",
        name: "projects",
        type: "base",
        system: false,

        listRule: "@request.auth.id = userId.id",
        viewRule: "@request.auth.id = userId.id",
        createRule: "@request.auth.id = userId.id",
        updateRule: "@request.auth.id = userId.id",
        deleteRule: "@request.auth.id = userId.id",

        fields: [
            {
                id: "text3208210256",
                name: "id",
                type: "text",
                system: true,
                required: true,
                primaryKey: true,
                hidden: false,
                presentable: false,
                min: 15,
                max: 15,
                pattern: "^[a-z0-9]+$",
                autogeneratePattern: "[a-z0-9]{15}"
            },
            {
                id: "text1579384326",
                name: "name",
                type: "text",
                system: false,
                required: false,
                primaryKey: false,
                hidden: false,
                presentable: false,
                min: 0,
                max: 0,
                pattern: "",
                autogeneratePattern: ""
            },
            {
                id: "relation2375276105",
                name: "userId",
                type: "relation",
                system: false,
                required: false,
                hidden: false,
                presentable: false,
                collectionId: "_pb_users_auth_",
                cascadeDelete: true,
                required: true,
                minSelect: 1,
                maxSelect: 1
            },
            {
                id: "autodate2990389176",
                name: "createdAt",
                type: "autodate",
                system: false,
                hidden: false,
                presentable: false,
                onCreate: true,
                onUpdate: false
            },
            {
                id: "autodate3332085495",
                name: "updatedAt",
                type: "autodate",
                system: false,
                hidden: false,
                presentable: false,
                onCreate: true,
                onUpdate: true
            }
        ],

        indexes: []
    });

    app.save(collection);
}, (app) => {
    const collection = app.findCollectionByNameOrId(
        "pbc_1901958808"
    );

    app.delete(collection);
});
