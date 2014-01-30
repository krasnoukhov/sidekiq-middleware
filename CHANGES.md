0.2.1
-----------

- Make middleware work properly even for ```Sidekiq::Extensions``` workers ([dimko](https://github.com/dimko))

0.2.0
-----------

- Fix redundant scheduled jobs locking when ```unique``` is not set to ```:all``` ([dimko](https://github.com/dimko))

0.1.4
-----------

- Make sure that scheduled unique jobs correctly move from the queue to work ([Sutto](https://github.com/Sutto))

0.1.3
-----------

- Constantize string worker_class in client middleware, require newest Sidekiq ([dimko](https://github.com/dimko))

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