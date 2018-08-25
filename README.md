# Summon-Mothership.sh

NAT-traversing SSH VPN: proxy your beefy supercomputer through your puny laptop!
![Alt Text](https://i.redditmedia.com/vsWQAnzjp0da58G_j6Oh-JmfiBlGgHiwM7A6qluEqW4.jpg?s=a9c2461b630e95e48fc44dc70ae7eeee)

## Getting Started

1. Clone this repo, and either copy the file summon-mothership.sh to your $PATH directory, or symlink to it.
2. Prepare the mothership: 'summon-mothership -p remoteport -l localport -c user@remotebox'. Does a key exchange and tries to install the sshuttle package on the remote box.
3. Summon it to your LAN: 'summon-mothership -p remoteport -l localport user@remotebox'

## Built With

* [sshuttle](https://github.com/sshuttle/sshuttle) - To proxy the remote box's connection through your local device.

## Authors

* **Olivier Lemelin** - *Initial work* - [goatz_overload](https://github.com/zante)


## Acknowledgments

* Many thanks to Brian May for maintaining sshuttle.


