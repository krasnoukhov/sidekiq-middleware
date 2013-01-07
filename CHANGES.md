0.0.6
-----------

- Now all unique locks are prefixed with "locks:unique:" and could be found using wildcard

0.0.5
-----------

- Fixed arguments passed to Hash#slice to be convinient with ActiveSupport slice

0.0.4
-----------

- Fixed Hash#slice (bnorton)

0.0.3
-----------

- Refactored and simplified the UniqueJobs middleware server and client as well as only enforcing the uniqueness of the payload across the keys for class, queue, args, and at (bnorton)

0.0.2
-----------

- Added tests

Initial release!
-----------

- UniqueJobs