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

const DonorBadges = {} as Record<string, Array<Record<"tooltip" | "badge", string>>>;

let MallCordDonorBadges = {} as Record<string, Array<Record<"tooltip" | "badge", string>>>;

const MallCordFounderBadge: ProfileBadge = {
    id: "mallcord_founder_badge",
    description: "MallCord Founder",
    iconSrc: FOUNDER_BADGE,
    position: BadgePosition.START,
    shouldShow: ({ userId }) => userId === "1469765555480297723",
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
    shouldShow: ({ userId }) => userId === "1469765555480297723",
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
    shouldShow: ({ userId }) => shouldShowMallCordContributorBadge(userId),
    onClick: (_, { userId }) => openContributorModal(UserStore.getUser(userId)),
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

        return Object.values(Plugins).some(p => {
            const pluginMeta = PluginMeta[p.name];

            return pluginMeta?.userPlugin &&
                p.authors.some(a => a.id.toString() === userId);
        });
    },
    onClick: (_, { userId }) => openContributorModal(UserStore.getUser(userId)),
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
    shouldShow: ({ userId }) => MALLCORD_SUPPORTER_IDS.has(userId),
    onClick: () => VencordNative.native.openExternal("https://ko-fi.com/privatemallcord"),
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
        MallCordDonorBadges[userId]?.some(badge => badge.tooltip === "MallCord Donor") ?? false,
    onClick: () => VencordNative.native.openExternal("https://ko-fi.com/privatemallcord"),
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
    shouldShow: ({ userId }) => userId === "1431018556639936673",
    onClick: () => MaceSafeModal(),
    props: {
        style: {
            borderRadius: "50%",
            transform: "scale(0.9)"
        }
    },
};

async function loadBadges(url: string, noCache = false) {
    const init = {} as RequestInit;

    if (noCache) init.cache = "no-cache";

    return await fetch(url, init).then(r => r.json());
}

async function loadAllBadges(noCache = false) {
    const mallcordBadges = await loadBadges("https://badge.equicord.org/badges.json", noCache);

    MallCordDonorBadges = mallcordBadges;
}

let intervalId: any;

export function BadgeContextMenu({
    badge
}: {
    badge: Omit<ProfileBadge, "id"> & BadgeUserArgs;
}) {
    return (
        <Menu.Menu
            navId="vc-badge-context"
            onClose={ContextMenuApi.closeContextMenu}
            aria-label="Badge Options"
        >
            {badge.description && (
                <Menu.MenuItem
                    id="vc-badge-copy-name"
                    label="Copy Badge Name"
                    action={() => copyWithToast(badge.description!)}
                />
            )}

            {badge.iconSrc && (
                <Menu.MenuItem
                    id="vc-badge-copy-link"
                    label="Copy Badge Image Link"
                    action={() => copyWithToast(badge.iconSrc!)}
                />
            )}
        </Menu.Menu>
    );
}

export default definePlugin({
    name: "BadgeAPI",
    description: "API to add badges to users",
    authors: [Devs.Megu, Devs.Ven, Devs.TheSun],
    required: true,

    patches: [
        {
            find: "#{intl::PROFILE_USER_BADGES}",
            replacement: [
                {
                    match: /alt:" ","aria-hidden":!0,src:.{0,50}(\i).iconSrc/,
                    replace: "...$1.props,$&"
                },
                {
                    match: /(?<=forceOpen:.{0,40}?ariaHidden:!0,)children:(?=.{0,50}?(\i)\.id)/,
                    replace: "children:$1.component?$self.renderBadgeComponent({...$1}) :"
                },
                {
                    match: /href:(\i)\.link/,
                    replace: "...$self.getBadgeMouseEventHandlers($1),$&"
                }
            ]
        },
        {
            find: "getLegacyUsername(){",
            replacement: {
                match: /getBadges\(\)\{.{0,100}?return\[/,
                replace: "$&...$self.getBadges(this),"
            }
        }
    ],

    get DonorBadges() {
        return DonorBadges;
    },

    get MallCordDonorBadges() {
        return MallCordDonorBadges;
    },

    toolboxActions: {
        async "Refetch Badges"() {
            await loadAllBadges(true);

            Toasts.show({
                id: Toasts.genId(),
                message: "Successfully refetched badges!",
                type: Toasts.Type.SUCCESS
            });
        }
    },

    userProfileBadges: [
        MallCordFounderBadge,
        MallCordDevBadge,
        MallCordContributorBadge,
        UserPluginContributorBadge,
        MallCordSupporterBadge,
        MallCordDonorBadge,
        MallCordFriendBadge,
        MaceSafeBadge
    ],

    async start() {
        await loadAllBadges();

        clearInterval(intervalId);

        intervalId = setInterval(loadAllBadges, 1000 * 60 * 30);
    },

    stop() {
        clearInterval(intervalId);
    },

    getBadges(profile: {
        userId: string;
        guildId: string;
    }) {
        if (!profile) return [];

        try {
            return _getBadges(profile);
        } catch (e) {
            new Logger("BadgeAPI#getBadges").error(e);
            return [];
        }
    },

    renderBadgeComponent: ErrorBoundary.wrap(
        (badge: ProfileBadge & BadgeUserArgs) => {
            const Component = badge.component!;

            return <Component {...badge} />;
        },
        { noop: true }
    ),

    getBadgeMouseEventHandlers(badge: ProfileBadge & BadgeUserArgs) {
        const handlers = {} as Record<string, (e: React.MouseEvent) => void>;

        if (!badge) return handlers;

        const { onClick, onContextMenu } = badge;

        if (onClick) handlers.onClick = e => onClick(e, badge);
        if (onContextMenu) handlers.onContextMenu = e => onContextMenu(e, badge);

        return handlers;
    },

    getDonorBadges(userId: string) {
        return DonorBadges[userId]?.map((badge, idx) => ({
            id: `vencord_donor_badge_${idx}`,
            iconSrc: badge.badge,
            description: badge.tooltip,
            position: BadgePosition.START,
            props: {
                style: {
                    borderRadius: "50%",
                    transform: "scale(0.9)"
                }
            },
            onContextMenu(event, badge) {
                ContextMenuApi.openContextMenu(
                    event,
                    () => <BadgeContextMenu badge={badge} />
                );
            },
            onClick() {
                return VencordDonorModal();
            },
        } satisfies ProfileBadge));
    },

    getMallCordDonorBadges(userId: string) {
        return MallCordDonorBadges[userId]?.map((badge, idx) => ({
            id: `mallcord_donor_badge_${idx}`,
            iconSrc: badge.badge,
            description: badge.tooltip,
            position: BadgePosition.START,
            props: {
                style: {
                    borderRadius: "50%",
                    transform: "scale(0.9)"
                }
            },
            onContextMenu(event, badge) {
                ContextMenuApi.openContextMenu(
                    event,
                    () => <BadgeContextMenu badge={badge} />
                );
            },
            onClick() {
                return MallCordDonorModal();
            },
        } satisfies ProfileBadge));
    }
});
