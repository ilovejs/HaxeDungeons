package dungeons.systems;

import ash.core.Engine;
import ash.core.Entity;
import ash.tools.ListIteratingSystem;
import ash.ObjectHash;

import dungeons.components.Fighter;
import dungeons.nodes.FighterNode;

using dungeons.utils.EntityUtil;

class FightSystem extends ListIteratingSystem<FighterNode>
{
    private var attackListeners:ObjectHash<FighterNode, AttackRequestListener>;
    private var engine:Engine;

    public function new()
    {
        super(FighterNode, null, onNodeAdded, onNodeRemoved);
    }

    override public function addToEngine(engine:Engine):Void
    {
        this.engine = engine;
        attackListeners = new ObjectHash();
        super.addToEngine(engine);
    }

    override public function removeFromEngine(engine:Engine):Void
    {
        super.removeFromEngine(engine);
        for (node in attackListeners.keys())
            node.fighter.attackRequested.remove(attackListeners.get(node));
        attackListeners = null;
        this.engine = null;
    }

    private function onNodeAdded(node:FighterNode):Void
    {
        var listener = callback(onNodeAttackRequested, node);
        attackListeners.set(node, listener);
        node.fighter.attackRequested.add(listener);
    }

    private function onNodeAttackRequested(defender:FighterNode, attacker:Entity):Void
    {
        var attackerFighter:Fighter = attacker.get(Fighter);
        var damage:Int = attackerFighter.power - defender.fighter.defense;
        if (damage > 0)
        {
            defender.health.currentHP -= damage;

            if (attacker.isPlayer())
                MessageLogSystem.message("You hit " + defender.entity.getName() + " for " + damage + " HP.");
            else if (defender.entity.isPlayer())
                MessageLogSystem.message(attacker.getName() + " hits you for " + damage + " HP.");

            if (defender.health.currentHP <= 0)
            {
                engine.removeEntity(defender.entity);

                if (defender.entity.isPlayer())
                    MessageLogSystem.message("You die...");
                else
                    MessageLogSystem.message(defender.entity.getName() + " dies.");
            }
        }
    }

    private function onNodeRemoved(node:FighterNode):Void
    {
        var listener = attackListeners.get(node);
        attackListeners.remove(node);
        node.fighter.attackRequested.remove(listener);
    }
}
