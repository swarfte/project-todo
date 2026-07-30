/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = new Collection({
        id: "pbc_3577811883",
        name: "tasks",
        type: "base",
        system: false,

        listRule: "@request.auth.id = projectId.userId.id",
        viewRule: "@request.auth.id = projectId.userId.id",
        createRule: "@request.auth.id = projectId.userId.id",
        updateRule: "@request.auth.id = projectId.userId.id",
        deleteRule: "@request.auth.id = projectId.userId.id",

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
                id: "relation800313582",
                name: "projectId",
                type: "relation",
                system: false,
                required: false,
                hidden: false,
                presentable: false,
                collectionId: "pbc_1901958808",
                cascadeDelete: true,
                required: true,
                minSelect: 1,
                maxSelect: 1
            },
            {
                id: "bool56683945",
                name: "isCompleted",
                type: "bool",
                system: false,
                required: false,
                hidden: false,
                presentable: false
            },
            {
                id: "date3275789471",
                name: "dueDate",
                type: "date",
                system: false,
                required: false,
                hidden: false,
                presentable: false,
                min: "",
                max: ""
            },
            {
                id: "text2387474946",
                name: "previousTaskId",
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
                id: "date1718663312",
                name: "completedAt",
                type: "date",
                system: false,
                required: false,
                hidden: false,
                presentable: false,
                min: "",
                max: ""
            },
            {
                id: "bool3642668614",
                name: "isFolded",
                type: "bool",
                system: false,
                required: false,
                hidden: false,
                presentable: false
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
        "pbc_3577811883"
    );

    app.delete(collection);
});
