# kartful 2 

Kubuntu Artful vagrant virtual machine Base with buildman vagrant full install for dotfiles sort



## Summary of the machine

The following has been installed:
- Full Buildman with all the apps in buildman for a VirtualBox installation, exept the VirtualBox tools from Buildman as it breaks the video.


## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Installed

List of installations done:
- Buildman
-- Kernel Update
-- KDE Updates
-- Update, disk update and full update

### Prerequisites

buildmanbuildman  The software you need to install and how to install them:

```
VirtualBox
vagrant
```

### Installing

A step by step series of examples that tell you have to get a development env running

Say what the step will be

```
# vagrant ssh -c "/srv/share/buildman/buildman.sh"
# vagrant ssh -c "tail -f buildmandebug.log"
```

And repeat

```
until finished
```

End with an example of getting some data out of the system or using it for a little demo

## Running the tests

Explain how to run the automated tests for this system

### Break down into end to end tests

Explain what these tests test and why

```
# vagrant ssh -c "sudo apt update && sudo apt -y upgrade && sudo apt -y dist-upgrade && sudo apt -y full-upgrade && sudo apt install -yf"
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone who's code was used
* Inspiration
* etc
