

#Chewbacca: The Force needs coordinates.
#You need this first in order to see if you can authenticate to GCP

#You need to change Project, Region, and Creds

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" 
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }

  }
}

provider "google" {
  project = "dusty-cloud-james-kent"
  region  = "us-central1"
}

resource "local_file" "favorite_food" {
  content  = "Pizza is the best food in the world."
  filename = "favorite_food.txt"
  
}


