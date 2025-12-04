const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * AUTO-SCORING — pokreće se kada admin unese stvarne rezultate
 */
exports.scoreRound = functions.firestore
    .document("timovi/aktivni")
    .onUpdate(async (change, context) => {

        const after = change.after.data();

        const rez1 = after.stvarnirezultat1;
        const rez2 = after.stvarnirezultat2;
        const rez3 = after.stvarnirezultat3;
        const rez4 = after.stvarnirezultat4;

        // Ako nisu svi rezultati uneseni → prekid
        if (!rez1 || !rez2 || !rez3 || !rez4) return;

        const r1 = parseInt(rez1);
        const r2 = parseInt(rez2);
        const r3 = parseInt(rez3);
        const r4 = parseInt(rez4);

        const usersSnap = await db.collection("users").get();

        for (const doc of usersSnap.docs) {
            const d = doc.data();

            let pts = 0;

            const t1 = parseInt(d.tip1 || 0);
            const t2 = parseInt(d.tip2 || 0);
            const t3 = parseInt(d.tip3 || 0);
            const t4 = parseInt(d.tip4 || 0);

            // -----------------------
            // PRVA UTAKMICA
            // -----------------------
            const exact1 = t1 === r1 && t2 === r2;
            const outcome1 = Math.sign(t1 - t2) === Math.sign(r1 - r2);

            if (exact1) pts += 15;
            else if (outcome1) pts += 5;

            // -----------------------
            // DRUGA UTAKMICA
            // -----------------------
            const exact2 = t3 === r3 && t4 === r4;
            const outcome2 = Math.sign(t3 - t4) === Math.sign(r3 - r4);

            if (exact2) pts += 15;
            else if (outcome2) pts += 5;

            // BONUS ako su oba tačna
            if (exact1 && exact2) pts += 15;

            const globalScore = parseInt(d.score || 0) + pts;

            await doc.ref.update({
                score: globalScore.toString(),
                lastRoundScore: pts,
                lastUpdated: Date.now(),
            });
        }

        return;
    });

