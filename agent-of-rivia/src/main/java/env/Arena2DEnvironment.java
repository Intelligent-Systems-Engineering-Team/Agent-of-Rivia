package env;
import jason.asSyntax.ASSyntax;
import jason.asSyntax.Literal;
import jason.asSyntax.Structure;
import jason.environment.Environment;
import jason.stdlib.prefix;
import utils.MonsterGenerator;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.Collection;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static env.Direction.*;

/**
 * Any Jason environment "entry point" should extend
 * jason.environment.Environment class to override methods init(),
 * updatePercepts() and executeAction().
 */
public class Arena2DEnvironment extends Environment {

    private static final Random RAND = new Random();



    // action literals
    public static final Literal moveForward = Literal.parseLiteral("move(" + FORWARD.name().toLowerCase() + ")");
    public static final Literal moveRight = Literal.parseLiteral("move(" + RIGHT.name().toLowerCase() + ")");
    public static final Literal moveLeft = Literal.parseLiteral("move(" + LEFT.name().toLowerCase() + ")");
    public static final Literal moveBackward = Literal.parseLiteral("move(" + BACKWARD.name().toLowerCase() + ")");
    public static final Literal moveRandom = Literal.parseLiteral("move(random)");

    static Logger logger = Logger.getLogger(Arena2DEnvironment.class.getName());

    private Arena2DModel model;
    private Arena2DView view;

    //hashmap to add monster type and the specs
    private final Map<String, String> monsterTypes = new HashMap<>();
    private final Map<String, Integer> monsterHealth = new HashMap<>();
    private final Map<String, Integer> monsterStrength = new HashMap<>();


    //record of monster specs
    private record MonsterSpec(String type, int health, int strength) {}


private MonsterSpec getMonsterSpec(String agentName) {
    String type = agentName.replaceAll("\\d+$", ""); // remove trailing numbers

    return switch (type) {
        case "drowner"  -> new MonsterSpec("drowner", 71, 24);
        case "siren"    -> new MonsterSpec("siren", 142, 48);
        case "wraith"   -> new MonsterSpec("wraith", 214, 71);
        case "werewolf" -> new MonsterSpec("werewolf", 285, 95);
        case "troll"    -> new MonsterSpec("troll", 356, 95);
        case "griffon"  -> new MonsterSpec("griffon", 400, 142);
        case "fiend"    -> new MonsterSpec("fiend", 499, 166);
        case "leshen"   -> new MonsterSpec("leshen", 500, 214);
        case "vampire"  -> new MonsterSpec("vampire", 600, 238);
        default -> throw new IllegalArgumentException("Unknown monster type for agent: " + agentName);
    };
}

private Literal selfStatsPercept(String agentName) {
    int hp = monsterHealth.getOrDefault(agentName, 0);
    int str = monsterStrength.getOrDefault(agentName, 0);
    return Literal.parseLiteral(String.format("self_stats(%d,%d)", hp, str));
}
    @Override
    public void init(final String[] args) {
        this.model = new Arena2DModelImpl(Integer.parseInt(args[0]), Integer.parseInt(args[1]));
        Arena2DGuiView view = new Arena2DGuiView(model);
        this.view = view;
        view.setVisible(true);
    }

    private void notifyModelChangedToView() {
        view.notifyModelChanged();
    }

    private boolean isWitcherInitialized = false;

    private void initializeAgentIfNeeded(String agentName) {
        if (!model.containsAgent(agentName)) {
   
        if (agentName.equals("witcher")) {
            model.setAgentPose(agentName, 0, 0, Orientation.NORTH);
        } else {
            int x = RAND.nextInt(20);
            int y = RAND.nextInt(20);

            model.setAgentPose(agentName, x, y, Orientation.NORTH);
            model.setAgentAlive(agentName);

            MonsterSpec spec = getMonsterSpec(agentName);

            monsterTypes.put(agentName, spec.type());
            monsterHealth.put(agentName, spec.health());
            monsterStrength.put(agentName, spec.strength());
        }
    }

        view.notifyModelChanged();
    }


  
    @Override
    public Collection<Literal> getPercepts(String agName) {
        initializeAgentIfNeeded(agName);

        Stream<Literal> basePercepts = Stream.of(
                surroundingPercepts(agName),
                neighboursPercepts(agName)
        ).flatMap(Collection::stream);

        Stream<Literal> extraPercepts;

        if ("witcher".equals(agName)) {
            extraPercepts = addMonsterPercepts().stream();
        } else {
            extraPercepts = Stream.of(selfStatsPercept(agName));
        }

        Collection<Literal> dynamicPercepts = super.getPercepts(agName);

        return Stream.concat(
                Stream.concat(basePercepts, extraPercepts),
                dynamicPercepts == null ? Stream.empty() : dynamicPercepts.stream()
        ).collect(Collectors.toList());
    }

    

    private Literal proximityPerceptFor(Direction direction, Vector2D position) {
        if (model.getAgentByPosition(position).isPresent()) {
            return Literal.parseLiteral(String.format("robot(%s)", direction.name().toLowerCase()));
        } else if (model.isPositionOutside(position)) {
            return Literal.parseLiteral(String.format("obstacle(%s)", direction.name().toLowerCase()));
        } else {
            return Literal.parseLiteral(String.format("free(%s)", direction.name().toLowerCase()));
        }
    }

    private Collection<Literal> surroundingPercepts(String agent) {
        return model.getAgentSurroundingPositions(agent)
                .entrySet().stream()
                .map(it -> proximityPerceptFor(it.getKey(), it.getValue()))
                .collect(Collectors.toList());
    }

    private Collection<Literal> neighboursPercepts(String agent) {
        return model.getAgentNeighbours(agent).stream()
                .map(it -> String.format("neighbour(%s)", it))
                .map(Literal::parseLiteral)
                .collect(Collectors.toList());
    }

private Collection<Literal> addMonsterPercepts() {
    return model.getAllAgents().stream()
            .filter(name -> !name.equals("witcher"))
            .map(name -> {
                Vector2D pos = model.getAgentPosition(name);
                String type = monsterTypes.getOrDefault(name, "unknown");
                int hp = monsterHealth.getOrDefault(name, 0);
                int str = monsterStrength.getOrDefault(name, 0);
                String status = model.getAgentAliveStatus(name).toString().toLowerCase();

                return Literal.parseLiteral(String.format(
                        "monster(%s,%s,%d,%d,%s,%d,%d)",
                        name,
                        type,
                        (int) pos.getX(),
                        (int) pos.getY(),
                        status,
                        hp,
                        str
                ));
            })
            .collect(Collectors.toList());
}


    /**
     * The <code>boolean</code> returned represents the action "move"
     * (success/failure)
     */
    @Override
public boolean executeAction(final String ag, final Structure action) {
    initializeAgentIfNeeded(ag);
    final boolean result;

    if (action.equals(moveForward)) {
        result = model.moveAgent(ag, 1, FORWARD);

    } else if (action.equals(moveRight)) {
        result = model.moveAgent(ag, 1, RIGHT);

    } else if (action.equals(moveBackward)) {
        result = model.moveAgent(ag, 1, BACKWARD);

    } else if (action.equals(moveLeft)) {
        result = model.moveAgent(ag, 1, LEFT);

    } else if (action.equals(moveRandom)) {
        Direction rd = Direction.random();
        result = model.moveAgent(ag, 1, rd);

    } else if (action.getFunctor().equals("kill")) {
        String monsterName = action.getTerm(0).toString();
        result = model.setAgentDead(monsterName);

    } else if (action.getFunctor().equals("apply_damage")) {
        int dmg = Integer.parseInt(action.getTerm(0).toString());

        int currentHp = monsterHealth.getOrDefault(ag, 0);
        int newHp = Math.max(0, currentHp - dmg);
        monsterHealth.put(ag, newHp);

        if (newHp == 0) {
            model.setAgentDead(ag);
            logger.info(ag + " died.");
        } else {
            logger.info(ag + " took " + dmg + " damage. HP now: " + newHp);
        }

        result = true;

    } else {
        RuntimeException e = new IllegalArgumentException("Cannot handle action: " + action);
        logger.warning(e.getMessage());
        throw e;
    }

    try {
        Thread.sleep(1000L / model.getFPS());
    } catch (InterruptedException ignored) { }

    notifyModelChangedToView();
    return result;
}
}
