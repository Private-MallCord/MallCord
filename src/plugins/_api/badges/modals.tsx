/*
 * Vencord, a modification for Discord's desktop app
 * Copyright (c) 2022 Vendicated and contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
*/

import { Button } from "@components/Button";
import { Heart } from "@components/Heart";
import { OpenExternalIcon } from "@components/Icons";
import { openInviteModal } from "@utils/discord";
import { ButtonProps } from "@vencord/discord-types";
import { showToast } from "@webpack/common";

export function DonateButton({
    mallcord = false,
    className,
    ...props
}: Partial<ButtonProps> & { mallcord?: boolean; }) {

    const link = mallcord
        ? "https://ko-fi.com/privatemallcord"
        : "https://github.com/sponsors/Vendicated";

    return (
        <Button
            {...props}
            variant="none"
            size="medium"
            type="button"
            onClick={() => VencordNative.native.openExternal(link)}
            className={className || "vc-donate-button"}
        >
            <Heart />
            Donate
        </Button>
    );
}

export function InviteButton({
    className,
    ...props
}: Partial<ButtonProps>) {

    return (
        <Button
            {...props}
            variant="none"
            size="medium"
            type="button"
            onClick={async e => {
                e.preventDefault();

                openInviteModal("wKgT9j2xfN").catch(() =>
                    showToast("Invalid or expired invite"),
                );
            }}
            className={className || "vc-donate-button"}
        >
            Invite

            <OpenExternalIcon className="vc-invite-link" />
        </Button>
    );
}

export function TranslateButton({
    className,
    ...props
}: Partial<ButtonProps>) {

    const link =
        "https://weblate.equicord.org/projects/mallcord/";

    return (
        <Button
            {...props}
            variant="none"
            size="medium"
            type="button"
            onClick={() => VencordNative.native.openExternal(link)}
            className={className || "vc-translate-button"}
        >
            Translate Here
        </Button>
    );
}
