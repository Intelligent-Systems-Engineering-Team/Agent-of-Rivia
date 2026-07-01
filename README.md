# Agent of Rivia

## About

This project demonstrates a BDI agent operating in an environment where its goal is to hunt monsters. The agent reasons about the current situation, selects appropriate intentions, and decides whether to fight, move through the environment, or recover health. Its behaviour can be adjusted through the healing threshold, which makes the agent either more cautious or more willing to take risks. Use the scrollbar at the bottom to speed up the simulation.

![Demo](assets/demo.gif)
## How to Run

The project requires **Java 17**.

Run the project from the root directory:

```bash id="3s2lmi"
./gradlew runProjectMas
```

The project uses the Gradle wrapper, so Gradle does not need to be installed separately.
