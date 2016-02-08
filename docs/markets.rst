Markets
=======

The Marketplace is composed of many individual markets which each offer
computation of a specific algorithm.


Components
----------

Each algorithm is comprised of three distinct contracts.

* Broker
* Factory
* Execution Contract


Broker
^^^^^^

The *Broker* contract coordinates the requests and fulfillments for computation
for whatever algorithm they manage.  Each algorithm is packaged as a *Factory*
contract which contains meta-data about the computation.
