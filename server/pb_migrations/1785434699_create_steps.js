/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
    const collection = new Collection({
        id: "pbc_3297130162",
        name: "steps",
        type: "base",
        system: false,

        listRule: "@request.auth.id = taskId.projectId.userId.id",
        viewRule: "@request.auth.id = taskId.projectId.userId.id",
        createRule: "@request.auth.id = taskId.projectId.userId.id",
        updateRule: "@request.auth.id = taskId.projectId.userId.id",
        deleteRule: "@request.auth.id = taskId.projectId.userId.id",

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
                id: "relation1384045349",
                name: "taskId",
                type: "relation",
                system: false,
                required: false,
                hidden: false,
                presentable: false,
                collectionId: "pbc_3577811883",
                cascadeDelete: true,
                required: true,
                minSelect: 1,
                maxSelect: 1
            },
            {
                id: "text3635336749",
                name: "previousStepId",
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
                id: "bool56683945",
                name: "isCompleted",
                type: "bool",
                system: false,
                required: false,
                hidden: false,
                presentable: false
            },
            {
                id: "autodate2990389176",
                name: "created",
                type: "autodate",
                system: false,
                hidden: false,
                presentable: false,
                onCreate: true,
                onUpdate: false
            },
            {
                id: "autodate3332085495",
                name: "updated",
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
        "pbc_3297130162"
    );

    app.delete(collection);
});
