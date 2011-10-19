QUnit.specify "namespace", ->
    describe "namespace", ->

        myPC =
            classification: "PC"
            processor:
                clockSpeed: 2.66
                physicalCores: 4
                logicalCores: 2
                build: "Core i7 920"
                vendor: "Intel"
                l2Cache: "512 KB"
                l3Cache: "8 MB"
            gpu:
                make: "ATI"
                model: "Radeon HD 4890"
                ram: "1 GB"
                slot: "PCI Express 2.0"
                vendor: "XFX"
            memory: [
                {
                    bank: 1
                    slots: 2
                    sticks: [
                        {
                            brand: "OCZ"
                            pin: 240
                            size: "2 GB"
                            class: "DDR3"
                            speed: 1600
                        },
                        {
                            brand: "OCZ"
                            pin: 240
                            size: "2 GB"
                            class: "DDR3"
                            speed: 1600
                        }
                    ]
                },
                {
                    bank: 2
                    slots: 2
                    sticks: [
                        {
                            brand: "OCZ"
                            pin: 240
                            size: "2 GB"
                            class: "DDR3"
                            speed: 1600
                        },
                        {
                            brand: "OCZ"
                            pin: 120
                            size: "2 GB"
                            class: "DDR3"
                            speed: 1600
                        }
                    ]
                },
                {
                    bank: 3
                    slots: 2
                    sticks: [
                        {
                            brand: "OCZ"
                            pin: 240
                            size: "2 GB"
                            class: "DDR3"
                            speed: 1600
                        },
                        {
                            brand: "OCZ"
                            pin: 240
                            size: "2 GB"
                            class: "DDR3"
                            speed: 1600
                        }
                    ]
                }
            ]
            storage: [
                {
                    classification: "Hard Disk"
                    capacity: "1 TB"
                    rpms: 7200
                    vendor: "Western Digital"
                },
                {
                    classification: "Hard Disk"
                    capacity: "0 TB"
                    rpms: 7200
                    vendor: "Western Digital"
                },
                {
                    classification: "Hard Disk"
                    capacity: "1 TB"
                    rpms: 7200
                    vendor: "Western Digital"
                }
            ]
        myPC = replicant.create myPC, null, "myPC"

        console.log myPC

        myPC["myPC.storage.1.capacity"] = "1 TB"
        myPC["myPC.memory.1.sticks.1.pin"] = 240
        gpuRAM =  myPC["myPC.gpu.ram"]
        secondDiskSize = myPC.storage[1].capacity
        fourthRAMStickPinSize = myPC.memory[1].sticks[1].pin

        it "should have retrieved correct gpu ram", ->
            assert( gpuRAM ).equals("1 GB")

        it "should have correct capacity for disk 1", ->
            assert( secondDiskSize ).equals("1 TB")

        it "should have correct fourth ram stick pin size", ->
            assert( fourthRAMStickPinSize ).equals(240)

        it "should include namespace prefix at all levels", ->
            assert( myPC["myPC.classification"] ).equals("PC")