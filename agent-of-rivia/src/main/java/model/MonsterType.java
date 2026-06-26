package model;

public enum MonsterType {
    DROWNER("drowner", 71, 24),
    SIREN("siren", 142, 48),
    WRAITH("wraith", 214, 71),
    WEREWOLF("werewolf", 285, 95),
    TROLL("troll", 356, 95),
    GRIFFON("griffon", 400, 142),
    FIEND("fiend", 499, 166),
    LESHEN("leshen", 500, 214),
    VAMPIRE("vampire", 600, 238),
    UNKNOWN("unknown", 0, 0);

    private final String type;
    private final int health;
    private final int strength;

    MonsterType(String type, int health, int strength) {
        this.type = type;
        this.health = health;
        this.strength = strength;
    }

    public String type() {
        return type;
    }

    public int health() {
        return health;
    }

    public int strength() {
        return strength;
    }

    public static MonsterType fromAgentName(String agentName) {
        String type = agentName.replaceAll("\\d+$", "");

        for (MonsterType monsterType : values()) {
            if (monsterType.type.equals(type)) {
                return monsterType;
            }
        }

        throw new IllegalArgumentException("Unknown monster type for agent: " + agentName);
    }
}
