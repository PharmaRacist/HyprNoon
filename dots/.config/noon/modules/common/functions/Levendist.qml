pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton {
    // Utility functions
    function min2(a, b) {
        return a < b ? a : b;
    }

    function max2(a, b) {
        return a > b ? a : b;
    }

    function min3(a, b, c) {
        return min2(a, min2(b, c));
    }

    function max3(a, b, c) {
        return max2(a, max2(b, c));
    }

    // Levenshtein distance algorithm
    function levenshteinDistance(s1, s2) {
        const len1 = s1.length;
        const len2 = s2.length;

        if (len1 === 0)
            return len2;
        if (len2 === 0)
            return len1;

        if (len2 > len1) {
            [s1, s2] = [s2, s1];
        }

        const prev = new Array(s2.length + 1);
        const curr = new Array(s2.length + 1);

        for (let j = 0; j <= s2.length; j++) {
            prev[j] = j;
        }

        for (let i = 1; i <= s1.length; i++) {
            curr[0] = i;
            for (let j = 1; j <= s2.length; j++) {
                const cost = s1[i - 1] === s2[j - 1] ? 0 : 1;
                curr[j] = min3(prev[j] + 1       // deletion
                , curr[j - 1] + 1   // insertion
                , prev[j - 1] + cost // substitution
                );
            }
            [prev, curr] = [curr, prev];
        }

        return prev[s2.length];
    }

    // Fuzzy partial ratio (substring match)
    function partialRatio(shortS, longS) {
        const lenS = shortS.length;
        const lenL = longS.length;
        let best = 0.0;

        if (lenS === 0)
            return 1.0;

        for (let i = 0; i <= lenL - lenS; i++) {
            const sub = longS.slice(i, i + lenS);
            const dist = levenshteinDistance(shortS, sub);
            const score = 1.0 - (dist / lenS);
            if (score > best)
                best = score;
        }

        return best;
    }

    // Balanced full + partial fuzzy score
    function computeScore(s1, s2) {
        if (s1 === s2)
            return 1.0;

        const dist = levenshteinDistance(s1, s2);
        const maxLen = max2(s1.length, s2.length);
        if (maxLen === 0)
            return 1.0;

        const full = 1.0 - (dist / maxLen);
        const part = s1.length < s2.length ? partialRatio(s1, s2) : partialRatio(s2, s1);
        let score = 0.85 * full + 0.15 * part;

        if (s1 && s2 && s1[0] !== s2[0]) {
            score -= 0.05;
        }

        const lenDiff = Math.abs(s1.length - s2.length);
        if (lenDiff >= 3) {
            score -= 0.05 * lenDiff / maxLen;
        }

        let commonPrefixLen = 0;
        const minLen = min2(s1.length, s2.length);
        for (let i = 0; i < minLen; i++) {
            if (s1[i] === s2[i])
                commonPrefixLen++;
            else
                break;
        }
        score += 0.02 * commonPrefixLen;

        if (s1.includes(s2) || s2.includes(s1)) {
            score += 0.06;
        }

        return Math.max(0.0, Math.min(1.0, score));
    }

    // Text match score optimized for search ranking
    function computeTextMatchScore(s1, s2) {
        if (s1 === s2)
            return 1.0;

        const dist = levenshteinDistance(s1, s2);
        const maxLen = max2(s1.length, s2.length);
        if (maxLen === 0)
            return 1.0;

        const full = 1.0 - (dist / maxLen);
        const part = s1.length < s2.length ? partialRatio(s1, s2) : partialRatio(s2, s1);
        let score = 0.4 * full + 0.6 * part;

        const lenDiff = Math.abs(s1.length - s2.length);
        if (lenDiff >= 10) {
            score -= 0.02 * lenDiff / maxLen;
        }

        let commonPrefixLen = 0;
        const minLen = min2(s1.length, s2.length);
        for (let i = 0; i < minLen; i++) {
            if (s1[i] === s2[i])
                commonPrefixLen++;
            else
                break;
        }
        score += 0.01 * commonPrefixLen;

        if (s1.includes(s2) || s2.includes(s1)) {
            score += 0.2;
        }

        return Math.max(0.0, Math.min(1.0, score));
    }
}
