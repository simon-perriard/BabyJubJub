// SPDX-License-Identifier: UNLICENSED
// Author: Simon Perriard
// Contact: simon.perriard@chainsecurity.com
// 2023

// Formulas from https://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended.html

pragma solidity ^0.8.0;

library BJJLib {

    struct AffinePoint {
        uint256 x;
        uint256 y;
    }

    struct ExtProjectivePoint {
        uint256 x;
        uint256 y;
        uint256 z;
        uint256 t;
    }

    // Implementation of the Baby JubJub twisted Edward's curve
    // a*x^2 + y^2 = 1 + d*x^2y^2

    uint256 constant a = 168700;
    uint256 constant d = 168696;

    // Base field modulo
    uint256 constant r = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // Generator of the curve
    uint256 constant CG_x = 995203441582195749578291179787384436505546430278305826713579947235728471134;
    uint256 constant CG_y = 5472060717959818805561601436314318772137091100104008585924551046643952123905;

    // Order of the subgroup
    uint256 constant l = 2736030358979909402780800718157159386076813972158567259200215660948447373041;

    // Generator for the subgroup of order l
    uint256 constant G_x = 5299619240641551281634865583518297030282874472190772894086521144482721001553;
    uint256 constant G_y = 16950150798460657717958625567821834550301663161624707787222815936182638968203;

    function curveGenerator() public pure returns(AffinePoint memory p){
        p.x = CG_x;
        p.y = CG_y;
    }

    function subgroupGenerator() public pure returns(AffinePoint memory p){
        p.x = G_x;
        p.y = G_y;
    }

    function id() public pure returns(AffinePoint memory p){
        p.x = 0;
        p.y = 1;
    }

    function _mulModr(uint256 s, uint256 t) internal pure returns(uint256 res){
        res = mulmod(s, t, r);
    }

    /// (s - t) % r
    function _subModr(uint256 s, uint256 t) internal pure returns(uint256 res){
        require(t<=r);
        res = addmod(s, r-t, r);
    }

    function _invModr(uint256 s) internal view returns(uint256 res) {
        res = _modExpr(s, r-2);
    }

    function _modExpr(uint256 base, uint256 exponent) internal view returns(uint256 res) {
        bool success;
        
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-198.md
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), base)
            mstore(add(freemem, 0x80), exponent)
            mstore(add(freemem, 0xA0), r)
            success := staticcall(
                gas(),
                5,
                freemem,
                0xC0,
                freemem,
                0x20
            )
            res := mload(freemem)
        }
        require(success, "Modular exponentiation failed");
    }

    function isOnCurve(AffinePoint memory aP) public pure returns(bool) {
        uint256 x2 = _mulModr(aP.x, aP.x);
        uint256 y2 = _mulModr(aP.y, aP.y);
        return addmod(_mulModr(a, x2), y2, r) == addmod(1, _mulModr(d, _mulModr(x2, y2)), r);
    }

    function toExtProjective(AffinePoint memory aP) public pure returns(ExtProjectivePoint memory p) {
        // X = x1
        // Y = y1
        // Z = 1
        // T = x1*y1 / Z
        p.x = aP.x;
        p.y = aP.y;
        p.t = _mulModr(aP.x, aP.y);
        p.z = 1;
    }

    function toAffine(ExtProjectivePoint memory p) public view returns(AffinePoint memory aP) {
        // x = X/Z
        // y = Y/Z
        uint256 inv_Z = _invModr(p.z);
        //revert("TODO");
        aP.x = _mulModr(p.x, inv_Z);
        aP.y = _mulModr(p.y, inv_Z);
    }

    function _doubleExtProjectiveGeneric(ExtProjectivePoint memory p) internal view returns(ExtProjectivePoint memory p2) {
        uint256 A = _mulModr(p.x, p.x);
        uint256 B = _mulModr(p.y, p.y);
        uint256 C = _mulModr(2, _mulModr(p.z, p.z));
        uint256 D = _mulModr(a, A);
        uint256 E = _subModr(_modExpr(addmod(p.x, p.y, r), 2), addmod(A, B, r));
        uint256 G = addmod(D, B, r);
        uint256 F = _subModr(G, C);
        uint256 H = _subModr(D, B);

        p2.x = _mulModr(E, F);
        p2.y = _mulModr(G, H);
        p2.t = _mulModr(E, H);
        p2.z = _mulModr(F, G);
    }

    function double(AffinePoint memory aP) public view returns(AffinePoint memory aP2) {
        ExtProjectivePoint memory p = toExtProjective(aP);
        aP2 = toAffine(_doubleExtProjectiveGeneric(p));
        assert(isOnCurve(aP2));
    }

    function _addExtProjectiveGeneric(ExtProjectivePoint memory p1, ExtProjectivePoint memory p2) public pure returns(ExtProjectivePoint memory p3) {
        uint256 A = _mulModr(p1.x, p2.x);
        uint256 B = _mulModr(p1.y, p2.y);
        uint256 C = _mulModr(p1.z, p2.t);
        uint256 D = _mulModr(p1.t, p2.z);
        uint256 E = addmod(D, C, r);
        uint256 F = addmod(_mulModr(_subModr(p1.x, p1.y), addmod(p2.x, p2.y, r)), _subModr(B, A), r);
        uint256 G = addmod(B, _mulModr(a, A), r);
        uint256 H = _subModr(D, C);

        p3.x = _mulModr(E, F);
        p3.y = _mulModr(G, H);
        p3.t = _mulModr(E, H);
        p3.z = _mulModr(F, G);
    }

    function add(AffinePoint memory aP1, AffinePoint memory aP2) public view returns(AffinePoint memory aP3) {
        ExtProjectivePoint memory p1 = toExtProjective(aP1);
        ExtProjectivePoint memory p2 = toExtProjective(aP2);
        aP3 = toAffine(_addExtProjectiveGeneric(p1, p2));
        assert(isOnCurve(aP3));
    }

    function _doubleAndAdd(AffinePoint memory aP, uint256 scalar) internal view returns(ExtProjectivePoint memory p2) {

        ExtProjectivePoint memory p = toExtProjective(aP);
        p2 = toExtProjective(id());

        while (scalar != 0) {
            if ((scalar & 0x1) != 0) {
                p2 = _addExtProjectiveGeneric(p2, p);
            }

            p = _doubleExtProjectiveGeneric(p);

            scalar /= 2;
        }

        return p2;
    }

    function mul(AffinePoint memory aP, uint256 scalar) public view returns(AffinePoint memory aP2) {

        // Scale back the multiplier
        // TODO: add another version of mul where we are sure the point is in the subgroup
        // and we can do scalar%l
        if (scalar >= r) {
            scalar = scalar%r;
        }

        aP2 = toAffine(_doubleAndAdd(aP, scalar));
        assert(isOnCurve(aP2));
    }

    function isValidSubGroupPointNotId(AffinePoint memory aP) public view returns(bool){
        AffinePoint memory subGroupCheck = mul(aP, l);
        return (aP.x == 0 && aP.y == 1) && isOnCurve(aP) && isOnCurve(subGroupCheck) && (subGroupCheck.x == 0 && subGroupCheck.y == 1);
    }
}