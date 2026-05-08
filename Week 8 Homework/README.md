# Week 8 Homework — GCP Managed Instance Groups & Terraform

**Author:** James J. Kent  
**Branch:** feature/Jamesbranch  
**Topics:** Managed Instance Groups, Autoscaling, Autohealing, Terraform on GCP

---

## Resources & Documentation Used

| Resource | How It Was Used |
|---|---|
| [GCP Managed Instance Groups Overview](https://cloud.google.com/compute/docs/instance-groups) | Understanding MIG concepts, autoscaling, and autohealing configuration |
| [GCP Health Checks Docs](https://cloud.google.com/load-balancing/docs/health-checks) | Differentiating app-level vs. load balancer health checks |
| [Terraform google_compute_instance reference](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | Identifying required vs optional arguments, output attributes |
| [Terraform google provider changelog](https://registry.terraform.io/providers/hashicorp/google/latest) | Finding the latest provider version |
| [GCP Image families reference](https://cloud.google.com/compute/docs/images/os-details) | Locating the correct CentOS Stream 10 image family |
| `gcloud compute images list --project centos-cloud` | Confirming the exact image family name for CentOS Stream 10 |
| [Terraform style guide](https://developer.hashicorp.com/terraform/language/style) | Naming conventions and idiomatic formatting |
| [3-Tier Architecture — AWS/GCP whitepapers](https://cloud.google.com/architecture/web-app-reference-architecture) | Understanding how MIGs map to application tiers |

---

## Q & A

### What is the difference between high availability and fault tolerance? Which is best to strive for?

**High availability (HA)** means designing a system to minimize downtime — typically by using redundancy and automated failover so that if one component fails, another takes over with only brief interruption (e.g., 99.9% uptime SLA). **Fault tolerance** goes further: the system continues operating *with zero downtime* even when components fail, usually by running fully redundant parallel systems that absorb failures invisibly. Fault tolerance is technically superior, but it is significantly more expensive to design and operate. In most real-world cloud workloads, **high availability is the practical target** — fault tolerance is reserved for systems where even seconds of downtime are unacceptable (e.g., financial transactions, air traffic control).

---

### Explain the difference between autoscaling and elasticity. What is vertical and horizontal autoscaling? Is one better? Are they feasible on-prem?

**Elasticity** is the broader capability — the ability of a system to dynamically acquire or release resources in response to demand. **Autoscaling** is the *automated mechanism* that implements elasticity; it monitors metrics (CPU, memory, request rate) and triggers scaling actions without human intervention. **Vertical scaling** (scale up/down) means increasing or decreasing the resources on an *existing* instance — adding more CPU or RAM to the same machine. **Horizontal scaling** (scale out/in) means adding or removing *instances*. Horizontal scaling is generally preferred in cloud because it provides better fault tolerance, there's no upper ceiling tied to hardware, and instances can be distributed across zones. Vertical scaling has a hard limit based on the largest available machine type and requires downtime to resize. On-prem, vertical scaling is feasible (upgrade the server's hardware), but horizontal scaling is expensive and slow — you have to physically rack and provision new servers, making true autoscaling impractical without virtualization infrastructure like VMware.

---

### Explain the difference between managed and unmanaged instance groups.

A **Managed Instance Group (MIG)** provisions and manages VMs from an *instance template*, giving you autoscaling, autohealing, rolling updates, and multi-zone distribution — GCP handles the lifecycle of the underlying instances. An **Unmanaged Instance Group (UMIG)** is simply a static collection of pre-existing VMs that you group together manually; there is no autoscaling, no autohealing, and no uniform template enforced. UMIGs exist primarily to attach a set of existing heterogeneous VMs to a load balancer. For any new workload, a MIG is the correct choice.

---

### Explain the different use cases for health checks used by applications (instance groups) and health checks used by load balancers. Can they be the same? Are they different API calls? Should they be the same?

**Autohealing health checks** (configured on the MIG itself) determine whether an instance is *alive enough to keep running* — if an instance fails this check repeatedly, the MIG terminates and replaces it. **Load balancer health checks** determine whether an instance is *healthy enough to receive traffic* — a failing instance is removed from the backend pool but not necessarily deleted. They are configured separately and are indeed different API calls (`compute.instanceGroupManagers` vs. `compute.backendServices`). They *can* point to the same health check resource, but **they should generally be different**: the autohealing check should be more lenient (a longer failure threshold before replacing an instance, to avoid thrashing), while the load balancer check can be more aggressive about pulling unhealthy instances from rotation quickly. Using identical checks risks prematurely terminating instances that are just slow to start up.

---

### Explain in a few sentences what the 3-tier architecture is and how it relates to what you are learning.

The **3-tier architecture** separates an application into three layers: the **presentation tier** (web/frontend, serves HTTP to users), the **application tier** (business logic, processes requests), and the **data tier** (database, stores state). Each tier scales and fails independently. In GCP, this maps directly to: a load balancer fronting a MIG of web servers (tier 1), a MIG of app servers behind an internal load balancer (tier 2), and a managed database like Cloud SQL (tier 3). The MIG skills you're building now are the core building block for running tiers 1 and 2 of this pattern reliably.

---

## Runbook

### End Goal

Deploy a fully configured **Managed Instance Group (MIG)** in GCP via the Console (ClickOps) with autoscaling and autohealing enabled, distributed across multiple zones within a single region. The MIG should automatically replace unhealthy instances and scale instance count based on CPU load.

---

### Prerequisites

- GCP project with billing enabled and Compute Engine API active
- IAM role of at minimum **Compute Admin** on the project
- An existing **instance template** configured with the desired machine type, OS image, startup script, and network tags — the MIG will be built from this template
- Default VPC present (or a named VPC/subnet if not using default)
- Health check created in advance (HTTP on port 80 recommended for web workloads), or be prepared to create one during MIG setup

---

### Create the Managed Instance Group

1. Navigate to **Compute Engine → Instance Groups → Create Instance Group**
2. Select **Managed instance group (stateless)**
3. Set **Name** (e.g., `web-mig`)
4. Under **Instance template**, select your pre-built template
5. Set **Location** to **Multiple zones**, select your **Region** (e.g., `us-central1`)
   - Leave zone distribution as **Spread (recommended)** — this ensures GCP distributes instances across zones automatically
6. Set **Minimum number of instances** (e.g., `2`) and **Maximum** (e.g., `5`)

---

### Enable Autoscaling

1. Under **Autoscaling**, set mode to **On: add and remove instances to the group**
2. Set **Autoscaling signal** to **CPU utilization**, target **60%** (adjust per workload)
3. Set **Initialization period** to **60 seconds** (time before a new instance is included in metrics)
4. Set **Scale-in controls** if desired — recommended to set a stabilization window (e.g., 10 min) to avoid flapping

---

### Enable Autohealing

1. Under **Autohealing**, click **Add a health check**
2. Select an existing health check or create a new one (HTTP, port 80, request path `/`)
3. Set **Initial delay** to at least **300 seconds** — this prevents the MIG from prematurely replacing instances that are still bootstrapping via startup script

---

### Verify Multi-Zone Distribution

1. After the MIG is created, navigate into the MIG detail page
2. Under **VMs**, confirm instances appear in **at least 2 different zones** (e.g., `us-central1-a`, `us-central1-b`, `us-central1-c`)
3. To force a verification: manually delete one instance from the MIG — the MIG should automatically recreate it, potentially in a different zone

---

### Other Critical Config

- **Instance redistribution**: Ensure this is set to **Proactive** so GCP actively rebalances instances across zones when scaling
- **Update policy**: Set to **Opportunistic** for manual-controlled rollouts or **Proactive** for automatic rolling updates when the template changes
- **Named ports**: If attaching to a load balancer, define a named port (e.g., `http:80`) on the MIG so the backend service can target it correctly

---

## Terraform

### Required Arguments for a GCP VM (`google_compute_instance`)

The following arguments are mandatory — Terraform will error without them:

| Argument | Description |
|---|---|
| `name` | The name of the VM instance — must be unique within the project/zone |
| `machine_type` | The GCP machine type (e.g., `n2-standard-2`) |
| `zone` | The GCP zone where the instance will be created |
| `boot_disk` | Block defining the boot disk — requires a nested `initialize_params` with at minimum an `image` |
| `network_interface` | Block defining network attachment — at minimum must reference a `network` |

---

### Outputting Internal and External IP Addresses

After applying, Terraform exposes computed attributes on the `google_compute_instance` resource. The internal IP is accessed via:

```hcl
value = google_compute_instance.vm.network_interface[0].network_ip
```

The external IP (NAT IP assigned via `access_config`) is:

```hcl
value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
```

These were found by checking the **Attributes Reference** section of the [`google_compute_instance` Terraform docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#attributes-reference). The `network_interface` block is a list, so index `[0]` is used since only one interface is defined. `access_config` is also a list, so `[0]` gets the first (and only) external IP config.

---

### Two Non-Required Arguments

**`deletion_protection`**  
When set to `true`, this prevents the instance from being destroyed via `terraform destroy` or accidentally through the GCP console until the protection is explicitly removed. This is valuable in production to protect against accidental teardown of critical VMs. It defaults to `false`.

**`labels`**  
A map of key-value string pairs attached to the instance as metadata for organizational and billing purposes. Labels don't affect runtime behavior but are used to filter resources, attribute costs to teams/environments in billing reports, and enforce policy via IAM conditions. Example: `labels = { env = "dev", team = "platform" }`.

---

### Finding the Correct CentOS Stream 10 Image Format

The most reliable method is to query GCP directly:

```bash
gcloud compute images list --project centos-cloud --filter="family:centos-stream-10" --no-standard-images
```

This returns the image family name (`centos-stream-10`) and the hosting project (`centos-cloud`). In Terraform, rather than hardcoding a specific image name (which becomes stale as new images are published), use the image *family* so GCP always resolves to the latest image in that family:

```hcl
image = "projects/centos-cloud/global/images/family/centos-stream-10"
```

Alternatively, the [GCP OS image details page](https://cloud.google.com/compute/docs/images/os-details) lists all public image families and their projects.

---

### Difference Between `name`, `id`, and `self_link`

**`name`** is the user-defined argument you provide when writing the Terraform config — it's a human-readable string like `"my-vm"`. It's what you see in the GCP console and use in `gcloud` commands.

**`id`** is a *computed* attribute assigned by GCP after the resource is created. In GCP's Terraform provider, the `id` is typically the same as the `self_link` — a fully qualified path string (e.g., `projects/my-project/zones/us-central1-a/instances/my-vm`). It is not a numeric ID like in some other cloud providers.

**`self_link`** is also computed and contains the full REST API URL of the resource (e.g., `https://www.googleapis.com/compute/v1/projects/my-project/zones/us-central1-a/instances/my-vm`). It is used when other GCP resources need to reference this instance explicitly — for example, attaching a VM to a target pool or backend service. The key distinction: `name` is what *you* set, while `id` and `self_link` are what *GCP returns* after provisioning, and they are used for cross-resource references.