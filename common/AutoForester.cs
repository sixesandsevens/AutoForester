using System.Collections.Generic;
using HarmonyLib;
using RimWorld;
using UnityEngine;
using Verse;
using Verse.AI;

namespace AutoForester
{
    [HarmonyPatch(typeof(FloatMenuMakerMap), nameof(FloatMenuMakerMap.AddHumanlikeOrders))]
    public static class ContextMenuPatch
    {
        static void Postfix(Vector3 clickPos, Pawn pawn, List<FloatMenuOption> opts)
        {
            // bail out if the pawn or its map are missing
            if (pawn == null || pawn.Map == null)
            {
                return;
            }

            IntVec3 cell = IntVec3.FromVector3(clickPos);
            if (!cell.IsValid || cell.GetPlant(pawn.Map) == null)
            {
                return;
            }

            var jobDef = DefDatabase<JobDef>.GetNamedSilentFail("AutoForestJob");
            if (jobDef == null)
            {
                return;
            }

            opts.Add(new FloatMenuOption("Auto-Forest", () =>
            {
                Job job = JobMaker.MakeJob(jobDef, cell);
                pawn.jobs.TryTakeOrderedJob(job);
            }));
        }
    }
}
