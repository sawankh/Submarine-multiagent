Submarine-multiagent
=========================

Aplication that simulates an evironment with multi-agents that solve a certain problem.
* Vertion: 1.0.
* Project for the subject Sistemas Inteligentes, Grado en Ingenería Informática, Universidad de la Laguna.

## [Colaborators]()
* Adrián González Martín. Contact: <alu0100536836@ull.edu.es>
* Sawan Jagdish Kapai Harpalani. Contact: <alu0100694765@ull.edu.es>
* Sara Martín Molina. Contact: <alu0100537123@ull.edu.es>

## [License](http://www.gnu.org/licenses/gpl-3.0.html) ![LICENSE](http://www.gnu.org/graphics/gplv3-88x31.png)
This project is under a GNU license.

## Project Description
Each submarine is an agent that will handle from the place where all the submarines are released and go to the area that has been assigned to start exploring. Before starting the simulation, the user can add obstacles shaped island to complicate the work of submarines. The oil leak is also an agent that appear in a random area of the map and start moving too slowly to a random direction. If the oil leak hits an island or against a wall will stop its movement at that point. If you spend some time with no submarine find the leak will be allowed to each agent can explore outside your area. This can be useful in those cases where an island assigned to divide into two and a submarine escape is in the part that can not scan the area underwater. By eliminating barriers any submarine can go to detect the spill. Once the spill is detected the submarine who finds it will have to warn others. These interrupt the scan being done to the place where the discharge was found. When you get will go clean up the spill and locate the leak. Once you locate submarines will repair and return the boat of departure.

## Programming language.
NetLogo is a functional programming language [22] with “turtles” that represent the agents and “patches” that represent a given point into the simulation space. Both of these may have multiple properties that can be defined by the user such as age, color, and position.

In practice, the fact that NetLogo uses a functional programming language means that many language statements are almost read as sentences, and this enables even unskilled and untrained users to understand and learn it through the examples.

* [Netlogo](https://ccl.northwestern.edu/netlogo/)