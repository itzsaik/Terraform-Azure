variable "server_name" {  
    default = "web-server"
}

variable "locations" {
    type = "map"
    default = {  
        location1="westus2"
        location2="westeurope"
    }
}

variable "subnets"{
    type = "list"
    default = ["10.2.23.12","10.0.0.12"]
}