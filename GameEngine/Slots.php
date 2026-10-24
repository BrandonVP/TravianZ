<?php
/**
 * Local redesign (Empires of Rome): which village slots are resource fields.
 *
 * fdata slots: 1-18 resource fields, 19-38 village buildings, 39 rally point,
 * 40 wall, 41-44 extra village building slots, 45-46 extra resource fields
 * (gold mines or a normal field, per village type - see LAYOUTS below),
 * 99 Wonder of the World. Code that used to say "slot <= 18 is a field"
 * asks Slots::isField() instead.
 */
class Slots
{
    /** Building id of the gold mine (a resource field producing village gold). */
    const GOLD_MINE = 51;

    /** The two resource field slots added after the original 18. */
    const EXTRA_FIELDS = array(45, 46);

    /**
     * Field design per village type (wdata.fieldtype 1-12): what slots 45 and
     * 46 hold, and optionally one original field turned into something else.
     * Types not listed get two gold mines in 45/46 and keep their 18 fields.
     * 1 gold mine: one of 45/46 is a normal field; 3 gold mines: 'convert'
     * turns one original field into a mine (its level is kept). The 9- and
     * 15-croppers (types 1 and 6) keep every crop field.
     */
    const LAYOUTS = array(
        // from the field-map art (img/fieldmap/f<type>.webp, 2026-10-23); types
        // not listed (1, 3, 6, 7, 10) have gold mines in 45 and 46
        2  => array(45 => 1, 46 => 51),               // 1 mine, extra woodcutter
        5  => array(45 => 2, 46 => 51),               // 1 mine, extra clay pit
        8  => array(45 => 51, 46 => 1),               // 1 mine, extra woodcutter
        12 => array(45 => 3, 46 => 51),               // 1 mine, extra iron mine
        4  => array('convert' => array(4 => 51)),    // 3 mines: clay pit 4 is a gold mine
        9  => array('convert' => array(1 => 51)),    // 3 mines: iron mine 1 is a gold mine
        11 => array('convert' => array(4 => 51)),    // 3 mines: iron mine 4 is a gold mine
    );

    /** array(45 => gid, 46 => gid, 'convert' => array(slot => gid)) for a village type. */
    public static function layout($type)
    {
        $l = self::LAYOUTS[(int) $type] ?? array();
        return array(
            45 => (int) ($l[45] ?? self::GOLD_MINE),
            46 => (int) ($l[46] ?? self::GOLD_MINE),
            'convert' => (array) ($l['convert'] ?? array()),
        );
    }

    /** Every fdata slot: fields, buildings 19-44, extra fields, WW (99). */
    public static function all()
    {
        return array_merge(range(1, 46), array(99));
    }

    /** True for a resource field slot (1-18, 45, 46). */
    public static function isField($slot)
    {
        $slot = (int) $slot;
        return ($slot >= 1 && $slot <= 18) || $slot === 45 || $slot === 46;
    }

    /** True for a resource field building type (woodcutter..cropland, gold mine). */
    public static function isFieldType($gid)
    {
        $gid = (int) $gid;
        return ($gid >= 1 && $gid <= 4) || $gid === self::GOLD_MINE;
    }

    /** All resource field slots. */
    public static function fields()
    {
        return array_merge(range(1, 18), self::EXTRA_FIELDS);
    }

    /** SQL condition: column holds a resource field slot. */
    public static function sqlIsField($col = 'field')
    {
        return '(' . $col . ' < 19 OR ' . $col . ' IN (45,46))';
    }

    /** SQL condition: column holds a village building slot. */
    public static function sqlIsBuilding($col = 'field')
    {
        return '(' . $col . ' > 18 AND ' . $col . ' NOT IN (45,46))';
    }
}
