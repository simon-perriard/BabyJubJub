// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "../src/BabyJubJub.sol";

contract BabyJubJubTest is Test {

    using BJJLib for BJJLib.AffinePoint;

    function xtestCurveGeneratorOnCurve() public {
        BJJLib.AffinePoint memory g = BJJLib.curveGenerator();
        assertTrue(g.isOnCurve());
    }

    function xtestSubgroupGeneratorOnCurve() public {
        BJJLib.AffinePoint memory sg = BJJLib.subgroupGenerator();
        assertTrue(sg.isOnCurve());
    }

    function xtestIdentityAddition() public {
        BJJLib.AffinePoint memory sg = BJJLib.subgroupGenerator();
        BJJLib.AffinePoint memory sg_id = BJJLib.id().add(sg);
        assertEq(sg.x, sg_id.x);
        assertEq(sg.y, sg_id.y);
    }

    function xtestSubgroupGeneratorDoubling() public {
        BJJLib.AffinePoint memory sg = BJJLib.subgroupGenerator();
        assertEq(sg.add(sg).x, sg.double().x);
        assertEq(sg.add(sg).y, sg.double().y);

        assertEq(sg.add(sg).x, sg.mul(2).x);
        assertEq(sg.add(sg).y, sg.mul(2).y);
    }

    function xtestSubgroupGeneratorTripling() public {
        BJJLib.AffinePoint memory sg = BJJLib.subgroupGenerator();

        BJJLib.AffinePoint memory tripled = sg.add(sg.add(sg));

        assertEq(tripled.x, sg.double().add(sg).x);
        assertEq(tripled.y, sg.double().add(sg).y);

        assertEq(tripled.x, sg.mul(3).x);
        assertEq(tripled.y, sg.mul(3).y);
    }

    function xtestIdentityDoublingIsIdentity() public {
        BJJLib.AffinePoint memory id = BJJLib.id();
        BJJLib.AffinePoint memory idDoubled = id.double();
        assertEq(id.x, idDoubled.x);
        assertEq(id.y, idDoubled.y);
    }

    function xtestSubgroupElementTimesOrderIsIdentity() public {
        BJJLib.AffinePoint memory sg = BJJLib.subgroupGenerator();
        BJJLib.AffinePoint memory multiplied = sg.mul(BJJLib.l);
        assertEq(BJJLib.id().x, multiplied.x);
        assertEq(BJJLib.id().y, multiplied.y);
    }

    function xtestCurveGeneratorShouldIsNotInSubgroup() public {
        BJJLib.AffinePoint memory g = BJJLib.curveGenerator();
        assertFalse(g.isValidSubGroupPointNotId());
    }

    function testGasOpti() public {
        BJJLib.AffinePoint memory sg = BJJLib.subgroupGenerator();

        sg.mul(BJJLib.l);
        sg.mul(564687654343);
        sg.mul(1725436586697640946858688965569256363112777243042596638790631055949823);
    }
}