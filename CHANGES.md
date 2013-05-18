0.1.2
-----------

- Fixed unique jobs server middleware to clear lock only when unique is enabled

0.1.1
-----------

- Improved lock expiration period for scheduled jobs

0.1.0
-----------

- Added ability to set custom lock key ([dimko](https://github.com/dimko))
- Removed forever option due to race condition issues. Added ability to manually operate unique locks instead

0.0.6
-----------

- Now all unique locks are prefixed with "locks:unique:" and could be found using wildcard

0.0.5
-----------

- Fixed arguments passed to Hash#slice to be convinient with ActiveSupport slice

0.0.4
-----------

- Fixed Hash#slice ([bnorton](https://github.com/bnorton))

0.0.3
-----------

- Refactored and simplified the UniqueJobs middleware server and client as well as only enforcing the uniqueness of the payload across the keys for class, queue, args, and at ([bnorton](https://github.com/bnorton))

0.0.2
-----------

- Added tests

Initial release!
-----------

- UniqueJobs