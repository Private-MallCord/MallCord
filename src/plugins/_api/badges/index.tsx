/*
 * Vencord, a modification for Discord's desktop app
 * Copyright (c) 2022 Vendicated and contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
*/

import "./fixDiscordBadgePadding.css";

import { _getBadges, BadgePosition, BadgeUserArgs, ProfileBadge } from "@api/Badges";
import ErrorBoundary from "@components/ErrorBoundary";
import { openContributorModal } from "@components/settings/tabs";
import { Devs } from "@utils/constants";
import { copyWithToast } from "@utils/discord";
import { Logger } from "@utils/Logger";
import { shouldShowMallCordContributorBadge } from "@utils/misc";
import definePlugin from "@utils/types";
import { ContextMenuApi, Menu, Toasts, UserStore } from "@webpack/common";

import Plugins, { PluginMeta } from "~plugins";

import {
    MallCordContributorModal,
    MallCordDevModal,
    MallCordDonorModal,
    MallCordFounderModal,
    MallCordFriendModal,
    MaceSafeModal,
    VencordDonorModal
} from "./modals";

const MALLCORD_CONTRIBUTOR_BADGE = "https://iili.io/Cfmxofj.png";
const USERPLUGIN_CONTRIBUTOR_BADGE = "https://iili.io/C3jZGrg.th.png";
const MALLCORD_DEV_BADGE = "https://iili.io/CfaMp94.png";
const FOUNDER_BADGE = "https://iili.io/CfaXwt2.png";
const FRIEND_BADGE = "https://iili.io/CqJFxlR.jpg";
const DONOR_BADGE = "https://iili.io/CfG9TKb.gif";
const MACESAFE_BADGE = "https://iili.io/CfDblEJ.th.gif";

const MALLCORD_SUPPORTER_IDS = new Set<string>([
    "1469765555480297723"
]);

const DonorBadges = {} as Record<
    string,
    Array<Record<"tooltip" | "badge", string>>
>;

let MallCordDonorBadges = {} as Record<
    string,
    Array<Record<"tooltip" | "badge", string>>
>;

const MallCordFounderBadge: ProfileBadge = {
    id: "mallcord_founder_badge",
    description: "MallCord Founder",
    iconSrc: FOUNDER_BADGE,
    position: BadgePosition.START,

    shouldShow: ({ userId }) =>
        userId === "1469765555480297723",

    onClick: () => MallCordFounderModal(),

    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};

const MallCordDevBadge: ProfileBadge = {
    id: "mallcord_dev_badge",
    description: "MallCord Dev",
    iconSrc: MALLCORD_DEV_BADGE,
    position: BadgePosition.START,

    shouldShow: ({ userId }) =>
        userId === "1469765555480297723",

    onClick: () => MallCordDevModal(),

    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};

const MallCordContributorBadge: ProfileBadge = {
    id: "mallcord_contributor_badge",
    description: "MallCord Contributor",
    iconSrc: MALLCORD_CONTRIBUTOR_BADGE,
    position: BadgePosition.START,

    shouldShow: ({ userId }) =>
        shouldShowMallCordContributorBadge(userId),

    onClick: (_, { userId }) =>
        openContributorModal(UserStore.getUser(userId)),

    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};

const UserPluginContributorBadge: ProfileBadge = {
    id: "user_plugin_contributor_badge",
    description: "User Plugin Contributor",
    iconSrc: USERPLUGIN_CONTRIBUTOR_BADGE,
    position: BadgePosition.START,

    shouldShow: ({ userId }) => {
        if (!IS_DEV) return false;

        const allPlugins = Object.values(Plugins);

        return allPlugins.some(p => {
            const pluginMeta = PluginMeta[p.name];

            return pluginMeta?.userPlugin &&
                p.authors.some(a => a.id.toString() === userId);
        });
    },

    onClick: (_, { userId }) =>
        openContributorModal(UserStore.getUser(userId)),

    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};

const MallCordSupporterBadge: ProfileBadge = {
    id: "mallcord_supporter_badge",
    description: "MallCord Supporter",
    iconSrc: DONOR_BADGE,
    position: BadgePosition.START,

    shouldShow: ({ userId }) =>
        MALLCORD_SUPPORTER_IDS.has(userId),

    onClick: () => {
        VencordNative.native.openExternal(
            "https://ko-fi.com/privatemallcord"
        );
    },

    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};

const MallCordDonorBadge: ProfileBadge = {
    id: "mallcord_donor_badge",
    description: "MallCord Donor",
    iconSrc: DONOR_BADGE,
    position: BadgePosition.START,

    shouldShow: ({ userId }) =>
        MallCordDonorBadges[userId]?.some(
            badge => badge.tooltip === "MallCord Donor"
        ) ?? false,

    onClick: () => {
        VencordNative.native.openExternal(
            "https://ko-fi.com/privatemallcord"
        );
    },

    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};

const MallCordFriendBadge: ProfileBadge = {
    id: "mallcord_friend_badge",
    description: "MallCord Friend",
    iconSrc: FRIEND_BADGE,
    position: BadgePosition.START,

    shouldShow: ({ userId }) =>
        userId === "1345836898106736790" ||
        userId === "1385182510396477557",

    onClick: () => MallCordFriendModal(),

    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};

const MaceSafeBadge: ProfileBadge = {
    id: "macesafe_badge",
    description: "Mace Safe",
    iconSrc: MACESAFE_BADGE,
    position: BadgePosition.START,

    shouldShow: ({ userId }) =>
        userId === "1431018556639936673",

    onClick: () => MaceSafeModal(),

    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};
