variable project {
  description = "Project ID"
}
variable region {
  description = "Region"
  # Значение по умолчанию
  default = "europe-west1"
}

variable zone {
  description = "Zone for instance"
  default     = "europe-west1-b"
}

variable machine_type {
  description = "Machine type for instance"
  default     = "n1-standard-1"
} 

variable disk_image {
  description = "Disk image"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh conection"
}

variable instances_count {
  default = 1
}
